# Use the official Go image as the base image
FROM golang:1.22-alpine AS BUILDER

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files
COPY go.mod ./

# Download the dependencies
RUN go mod download

# Copy the source code into the container
COPY . .

# Build the Go application
RUN go build -o getBird .

# Use minimal Alpine image for the final deployment
FROM alpine
WORKDIR /app
COPY --from=BUILDER /app/ ./

# Expose the port the app runs on
EXPOSE 4201

# Command to run the executable
CMD ["./getBird"]
