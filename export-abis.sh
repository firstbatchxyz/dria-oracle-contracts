#!/bin/bash
forge compile

cp ./out/LLMOracleCoordinator.sol/LLMOracleCoordinator.json ./abis/LLMOracleCoordinator.json
node ./abis/parseAbi.cjs ./abis/LLMOracleCoordinator.json

cp ./out/LLMOracleRegistry.sol/LLMOracleRegistry.json ./abis/LLMOracleRegistry.json
node ./abis/parseAbi.cjs ./abis/LLMOracleRegistry.json
