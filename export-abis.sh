#!/bin/bash
cp ./out/LLMOracleCoordinator.sol/LLMOracleCoordinator.json ./abis/LLMOracleCoordinator.json
node ./abis/parseAbi.js ./abis/LLMOracleCoordinator.json

cp ./out/LLMOracleRegistry.sol/LLMOracleRegistry.json ./abis/LLMOracleRegistry.json
node ./abis/parseAbi.js ./abis/LLMOracleRegistry.json
