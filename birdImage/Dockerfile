# Start from the official Go image
FROM golang:1.22-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files
COPY go.mod go.sum ./

# Download the dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN go build -o getBirdImage .

# Expose the port the app runs on
EXPOSE 4200

# Run the application
CMD ["./getBirdImage"]
