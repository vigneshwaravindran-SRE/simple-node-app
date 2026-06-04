# smaller and more secure than node:18
FROM node:18-alpine

# will set working directory inside container
WORKDIR /app

# Copy package files first
# Docker caches this layer — if package.json hasn't changed,
# npm install is skipped on next build (faster CI)

COPY package*.json ./

# Install only production deps + devDeps needed for tests

RUN npm install

# Copy rest of the app

COPY . .

# Expose the port your app listens on

EXPOSE 3000

# Run as non-root user — security best practice

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

CMD ["node", "index.js"]
