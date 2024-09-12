#!/bin/bash

echo "Node.js version:"
node -v

echo "Checking TensorFlow.js installation:"
node -e "console.log(require('@tensorflow/tfjs-node'))"

echo "Listing tfjs_binding.node:"
ls -l /app/node_modules/@tensorflow/tfjs-node/lib/napi-v8/tfjs_binding.node

echo "Checking shared library dependencies:"
ldd /app/node_modules/@tensorflow/tfjs-node/lib/napi-v8/tfjs_binding.node

echo "Starting the application:"
npm start