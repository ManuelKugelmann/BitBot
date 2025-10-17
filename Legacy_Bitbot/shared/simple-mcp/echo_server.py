#!/usr/bin/env python3
"""
SimpleMCP Server
A simple MCP server for testing connectivity and basic functionality
"""

import os
import sys
import json
import asyncio
from datetime import datetime
from typing import Dict, Any, List
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn

# MCP Protocol Models
class MCPRequest(BaseModel):
    method: str
    params: Dict[str, Any] = {}
    id: str

class MCPResponse(BaseModel):
    result: Dict[str, Any] = {}
    error: Dict[str, Any] = None
    id: str

class EchoRequest(BaseModel):
    message: str
    include_timestamp: bool = True

app = FastAPI(title="SimpleMCP Server", version="1.0.0")

# Service capabilities
SERVICE_CAPABILITIES = {
    "name": "simple-mcp",
    "version": "1.0.0",
    "description": "SimpleMCP - Simple echo service for testing MCP connectivity",
    "tools": {
        "echo": {
            "description": "Echo back a message with optional timestamp",
            "parameters": {
                "message": {"type": "string", "description": "Message to echo back"},
                "include_timestamp": {"type": "boolean", "description": "Include timestamp in response", "default": True}
            },
            "returns": {"type": "string", "description": "The echoed message"}
        },
        "ping": {
            "description": "Simple ping test",
            "parameters": {},
            "returns": {"type": "string", "description": "Pong response with timestamp"}
        },
        "capabilities": {
            "description": "Get service capabilities",
            "parameters": {},
            "returns": {"type": "object", "description": "Service capabilities and metadata"}
        }
    },
    "agent_usage": {
        "description": "Use this service to test MCP connectivity and basic communication",
        "examples": [
            "Test connection: call ping()",
            "Echo test: call echo('Hello from devcontainer')",
            "Get info: call capabilities()"
        ],
        "workflows": [
            {
                "name": "Connectivity Test",
                "steps": ["ping", "echo with test message", "capabilities check"],
                "description": "Verify MCP service is accessible and functioning"
            }
        ]
    },
    "performance": {
        "latency": "< 100ms",
        "rate_limit": "None",
        "availability": "99.9%"
    }
}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "simple-mcp",
        "timestamp": datetime.now().isoformat(),
        "uptime": "running"
    }

@app.get("/capabilities")
async def get_capabilities():
    """Get service capabilities"""
    return SERVICE_CAPABILITIES

@app.post("/mcp")
async def mcp_endpoint(request: MCPRequest):
    """Main MCP protocol endpoint"""
    try:
        if request.method == "ping":
            result = await handle_ping()
        elif request.method == "echo":
            result = await handle_echo(request.params)
        elif request.method == "capabilities":
            result = SERVICE_CAPABILITIES
        else:
            raise HTTPException(status_code=400, detail=f"Unknown method: {request.method}")
        
        return MCPResponse(result=result, id=request.id)
    
    except Exception as e:
        return MCPResponse(
            error={"code": -1, "message": str(e)},
            id=request.id
        )

@app.post("/echo")
async def echo_endpoint(request: EchoRequest):
    """Direct echo endpoint (non-MCP)"""
    return await handle_echo(request.dict())

@app.get("/ping")
async def ping_endpoint():
    """Direct ping endpoint (non-MCP)"""
    return await handle_ping()

async def handle_ping():
    """Handle ping requests"""
    return {
        "response": "pong",
        "timestamp": datetime.now().isoformat(),
        "service": "simple-mcp",
        "version": "1.0.0"
    }

async def handle_echo(params: Dict[str, Any]):
    """Handle echo requests"""
    message = params.get("message", "No message provided")
    include_timestamp = params.get("include_timestamp", True)
    
    if include_timestamp:
        timestamp = datetime.now().isoformat()
        echo_response = f"{message} [echoed at {timestamp}]"
    else:
        echo_response = message
    
    return {
        "original_message": message,
        "echo_response": echo_response,
        "timestamp": datetime.now().isoformat(),
        "service": "simple-mcp"
    }

@app.get("/")
async def root():
    """Root endpoint with service information"""
    return {
        "service": "simple-mcp",
        "version": "1.0.0",
        "description": "SimpleMCP - Simple echo service for testing MCP connectivity",
        "endpoints": {
            "/health": "Health check",
            "/capabilities": "Service capabilities",
            "/mcp": "MCP protocol endpoint",
            "/echo": "Direct echo endpoint",
            "/ping": "Direct ping endpoint"
        },
        "mcp_protocol": True,
        "timestamp": datetime.now().isoformat()
    }

async def register_with_registry():
    """Register this service with the MCP registry"""
    registry_url = os.getenv("REGISTRY_URL", "http://mcp-registry:8080")
    
    try:
        import requests
        response = requests.post(f"{registry_url}/refresh", timeout=5)
        if response.status_code == 200:
            print("Successfully registered with MCP registry")
        else:
            print(f"Registry registration returned status: {response.status_code}")
    except Exception as e:
        print(f"Could not register with registry: {e}")

@app.on_event("startup")
async def startup_event():
    """Initialize service on startup"""
    print("SimpleMCP Server starting up...")
    print(f"Service capabilities: {len(SERVICE_CAPABILITIES['tools'])} tools available")
    
    # Wait a bit for registry to be ready, then register
    await asyncio.sleep(5)
    await register_with_registry()

if __name__ == "__main__":
    port = int(os.getenv("PLACEHOLDER_MCP_PORT", 3000))
    print(f"Starting SimpleMCP Server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")