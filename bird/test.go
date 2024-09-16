package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGetBirdFactoid(t *testing.T) {
	// Mock the external API
	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mockBird := Bird{
			Name:        "Mocked Bird",
			Description: "This is a mocked bird for testing",
		}
		json.NewEncoder(w).Encode(mockBird)
	}))
	defer mockServer.Close()

	// Mock the image API
	mockImageServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("https://example.com/mocked-bird-image.jpg"))
	}))
	defer mockImageServer.Close()

	// Replace the actual URLs with mock server URLs
	origBirdAPI := "https://freetestapi.com/api/v1/birds/"
	origImageAPI := "http://localhost:4200"
	t.Setenv("BIRD_API_URL", mockServer.URL)
	t.Setenv("IMAGE_API_URL", mockImageServer.URL)

	// Modify the getBirdFactoid and getBirdImage functions to use the environment variables
	getBirdFactoid = func() Bird {
		res, err := http.Get(t.Getenv("BIRD_API_URL"))
		if err != nil {
			return defaultBird(err)
		}
		var bird Bird
		json.NewDecoder(res.Body).Decode(&bird)
		birdImage, err := getBirdImage(bird.Name)
		if err != nil {
			return defaultBird(err)
		}
		bird.Image = birdImage
		return bird
	}

	getBirdImage = func(birdName string) (string, error) {
		res, err := http.Get(t.Getenv("IMAGE_API_URL") + "?birdName=" + url.QueryEscape(birdName))
		if err != nil {
			return "", err
		}
		body, err := io.ReadAll(res.Body)
		return string(body), err
	}

	// Test the getBirdFactoid function
	bird := getBirdFactoid()

	// Assert the results
	if bird.Name != "Mocked Bird" {
		t.Errorf("Expected bird name to be 'Mocked Bird', got '%s'", bird.Name)
	}
	if bird.Description != "This is a mocked bird for testing" {
		t.Errorf("Expected bird description to be 'This is a mocked bird for testing', got '%s'", bird.Description)
	}
	if bird.Image != "https://example.com/mocked-bird-image.jpg" {
		t.Errorf("Expected bird image to be 'https://example.com/mocked-bird-image.jpg', got '%s'", bird.Image)
	}

	// Reset the original URLs
	t.Setenv("BIRD_API_URL", origBirdAPI)
	t.Setenv("IMAGE_API_URL", origImageAPI)
}
