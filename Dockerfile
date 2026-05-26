# =========================================================================
# STAGE 1: The Builder Stage
# =========================================================================
# Using a Node image as a construction environment to run syntax linters
FROM node:20-alpine AS builder

# Set the temporary compilation directory
WORKDIR /app

# Copy all repository source code files into the builder environment
COPY . .

# (Optional DevOps step) Clean up files or run lint checks if required here
# RUN npm run lint

# =========================================================================
# STAGE 2: The Production Serving Stage
# =========================================================================
# Pull a completely fresh, minimal Nginx image for the final artifact
FROM nginx:alpine

# Remove default Nginx placeholder website files
RUN rm -rf /usr/share/nginx/html/*

# CRITICAL MULTI-STAGE STEP: 
# Copy ONLY the static website files from the 'builder' stage 
# straight into Nginx's web root directory, leaving behind all build tools.
COPY --from=builder /app/ /usr/share/nginx/html/

# Expose standard web traffic port 80
EXPOSE 80

# Start Nginx in the foreground to keep the container running
CMD ["nginx", "-g", "daemon off;"]
