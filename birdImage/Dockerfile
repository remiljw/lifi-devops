# Start from the official Go image
FROM golang:1.22-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files
COPY go.mod  ./
COPY go.sum ./
# Download the dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN go build -o getBirdImage .

# Use minimal Alpine image for the final deployment
FROM alpine
WORKDIR /app
COPY --from=builder /app/ ./

# Expose the port the app runs on
EXPOSE 4200

# Run the application
CMD ["./getBirdImage"]
