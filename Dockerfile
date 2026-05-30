# Use a lightweight Nginx web server
FROM nginx:alpine

# Remove default Nginx placeholder website files
RUN rm -rf /usr/share/nginx/html/*

# Copy your local static file directly into Nginx's web folder
# (Replace 'index.html' with your actual filename if it is different)
COPY index.html /usr/share/nginx/html/

# Expose standard web traffic port 80
EXPOSE 80

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
