#!/usr/bin/env python3
"""
MCP Registry Service
Provides service discovery and capability management for MCP services
"""

import os
import json
import asyncio
from datetime import datetime
from typing import Dict, List, Optional
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
import docker
import requests
import uvicorn

app = FastAPI(title="MCP Registry", version="1.0.0")

# In-memory storage for service registry
services_registry: Dict[str, Dict] = {}

class MCPRegistry:
    def __init__(self):
        self.docker_client = None
        try:
            self.docker_client = docker.from_env()
        except Exception as e:
            print(f"Warning: Could not connect to Docker: {e}")
    
    async def discover_services(self) -> Dict[str, Dict]:
        """Discover MCP services in the network"""
        discovered = {}
        
        if not self.docker_client:
            return discovered
            
        try:
            # Get containers in the mcp-network
            network_name = os.getenv('MCP_NETWORK', 'mcp-services_mcp-network')
            containers = self.docker_client.containers.list()
            
            for container in containers:
                # Check if container is part of MCP network
                networks = container.attrs.get('NetworkSettings', {}).get('Networks', {})
                if any('mcp' in net_name.lower() for net_name in networks.keys()):
                    if container.name != 'mcp-registry':  # Don't include ourselves
                        service_info = await self.get_service_info(container)
                        if service_info:
                            discovered[container.name] = service_info
                            
        except Exception as e:
            print(f"Error discovering services: {e}")
            
        return discovered
    
    async def get_service_info(self, container) -> Optional[Dict]:
        """Get detailed information about a service"""
        try:
            # Get container info
            info = {
                'name': container.name,
                'status': container.status,
                'image': container.image.tags[0] if container.image.tags else 'unknown',
                'created': container.attrs.get('Created', ''),
                'ports': [],
                'networks': [],
                'capabilities': {},
                'health': 'unknown',
                'last_check': datetime.now().isoformat()
            }
            
            # Extract network information
            networks = container.attrs.get('NetworkSettings', {}).get('Networks', {})
            for net_name, net_info in networks.items():
                if 'mcp' in net_name.lower():
                    info['networks'].append({
                        'name': net_name,
                        'ip': net_info.get('IPAddress', ''),
                        'gateway': net_info.get('Gateway', '')
                    })
            
            # Extract port information
            port_bindings = container.attrs.get('NetworkSettings', {}).get('Ports', {})
            for container_port, host_bindings in port_bindings.items():
                if host_bindings:
                    for binding in host_bindings:
                        info['ports'].append({
                            'container_port': container_port,
                            'host_port': binding.get('HostPort', ''),
                            'host_ip': binding.get('HostIp', '')
                        })
            
            # Try to get health status
            health = container.attrs.get('State', {}).get('Health', {})
            if health:
                info['health'] = health.get('Status', 'unknown')
            
            # Try to get MCP capabilities if the service exposes them
            await self.fetch_service_capabilities(info)
            
            return info
            
        except Exception as e:
            print(f"Error getting service info for {container.name}: {e}")
            return None
    
    async def fetch_service_capabilities(self, service_info: Dict):
        """Attempt to fetch MCP capabilities from a service"""
        try:
            # Try common endpoints for capability information
            endpoints_to_try = [
                '/capabilities',
                '/mcp/capabilities',
                '/health',
                '/'
            ]
            
            for network in service_info.get('networks', []):
                ip = network.get('ip')
                if ip:
                    for port in [3000, 8000, 8080]:  # Common MCP ports
                        for endpoint in endpoints_to_try:
                            try:
                                url = f"http://{ip}:{port}{endpoint}"
                                response = requests.get(url, timeout=2)
                                if response.status_code == 200:
                                    data = response.json()
                                    if 'capabilities' in data:
                                        service_info['capabilities'] = data['capabilities']
                                    elif 'mcp' in data:
                                        service_info['capabilities'] = data
                                    return
                            except:
                                continue
                                
        except Exception as e:
            print(f"Could not fetch capabilities for {service_info['name']}: {e}")

registry = MCPRegistry()

@app.on_event("startup")
async def startup_event():
    """Initialize registry on startup"""
    print("MCP Registry starting up...")
    await refresh_services()

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "services_count": len(services_registry)
    }

@app.get("/services")
async def get_services():
    """Get all registered services"""
    return {
        "services": services_registry,
        "count": len(services_registry),
        "last_updated": datetime.now().isoformat()
    }

@app.get("/services/{service_name}")
async def get_service(service_name: str):
    """Get specific service information"""
    if service_name not in services_registry:
        raise HTTPException(status_code=404, detail=f"Service {service_name} not found")
    
    return services_registry[service_name]

@app.get("/capabilities/{service_name}")
async def get_service_capabilities(service_name: str):
    """Get capabilities for a specific service"""
    if service_name not in services_registry:
        raise HTTPException(status_code=404, detail=f"Service {service_name} not found")
    
    service = services_registry[service_name]
    return {
        "service": service_name,
        "capabilities": service.get('capabilities', {}),
        "last_updated": service.get('last_check', '')
    }

@app.post("/refresh")
async def refresh_services():
    """Manually refresh service discovery"""
    global services_registry
    
    print("Refreshing service registry...")
    discovered = await registry.discover_services()
    services_registry.update(discovered)
    
    return {
        "message": "Services refreshed",
        "services_found": len(discovered),
        "total_services": len(services_registry)
    }

@app.get("/", response_class=HTMLResponse)
async def web_interface():
    """Simple web interface for the registry"""
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>MCP Registry</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; }}
            .service {{ border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }}
            .service h3 {{ margin-top: 0; color: #333; }}
            .status {{ padding: 3px 8px; border-radius: 3px; font-size: 12px; }}
            .running {{ background-color: #d4edda; color: #155724; }}
            .stopped {{ background-color: #f8d7da; color: #721c24; }}
            pre {{ background-color: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }}
        </style>
    </head>
    <body>
        <h1>MCP Service Registry</h1>
        <p>Service discovery and capability management for MCP services</p>
        
        <div>
            <button onclick="location.reload()">Refresh</button>
            <button onclick="fetch('/refresh', {{method: 'POST'}}).then(() => location.reload())">Force Refresh</button>
        </div>
        
        <h2>Registered Services ({len(services_registry)})</h2>
        
        <div id="services">
            {"".join([f'''
            <div class="service">
                <h3>{name}</h3>
                <span class="status {service.get('status', 'unknown').lower()}">{service.get('status', 'unknown')}</span>
                <p><strong>Image:</strong> {service.get('image', 'unknown')}</p>
                <p><strong>Health:</strong> {service.get('health', 'unknown')}</p>
                <p><strong>Networks:</strong> {', '.join([net.get('name', '') for net in service.get('networks', [])])}</p>
                <p><strong>Capabilities:</strong></p>
                <pre>{json.dumps(service.get('capabilities', {{}}), indent=2)}</pre>
            </div>
            ''' for name, service in services_registry.items()]) if services_registry else '<p>No services found. Make sure MCP services are running.</p>'}
        </div>
        
        <script>
            // Auto-refresh every 30 seconds
            setTimeout(() => location.reload(), 30000);
        </script>
    </body>
    </html>
    """
    return html_content

if __name__ == "__main__":
    port = int(os.getenv("REGISTRY_PORT", 8080))
    print(f"Starting MCP Registry on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")