package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetBirdImage(t *testing.T) {
	// Create a mock HTTP server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Check if the request URL and client ID are correct
		if r.URL.Path != "/search/photos" || r.URL.Query().Get("client_id") != "P1p3WPuRfpi7BdnG8xOrGKrRSvU1Puxc1aueUWeQVAI" {
			t.Errorf("Unexpected request URL: %v", r.URL)
		}

		// Prepare a mock response
		response := ImageResponse{
			Results: []Links{
				{
					Urls: Urls{
						Thumb: "https://example.com/bird.jpg",
					},
				},
			},
		}
		json.NewEncoder(w).Encode(response)
	}))
	defer server.Close()

	// Replace the Unsplash API URL with our mock server URL
	// var query string
	originalQuery := "https://api.unsplash.com/search/photos"
	query = server.URL + "/search/photos"
	defer func() { query = originalQuery }()

	// Test cases
	testCases := []struct {
		name     string
		birdName string
		expected string
	}{
		{"Valid bird name", "sparrow", "https://example.com/bird.jpg"},
		{"Empty bird name", "", defaultImage()},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := getBirdImage(tc.birdName)
			if result != tc.expected {
				t.Errorf("Expected %s, but got %s", tc.expected, result)
			}
		})
	}
}
