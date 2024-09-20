package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"math/rand/v2"
	"net/http"
	"net/url"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var bird_image_url, bird_image_port string


type Bird struct {
	Name        string
	Description string
	Image       string
}

func init(){
	bird_image_url = os.Getenv("BIRD_IMAGE_URL")
	bird_image_port = os.Getenv("BIRD_IMAGE_PORT")
}

func defaultBird(err error) Bird {
	return Bird{
		Name:        "Bird in disguise",
		Description: fmt.Sprintf("This bird is in disguise because: %s", err),
		Image:       "https://www.pokemonmillennium.net/wp-content/uploads/2015/11/missingno.png",
	}
}

func getBirdImage(birdName string) (string, error) {
    res, err := http.Get(fmt.Sprintf("http://%s:%s?birdName=%s", bird_image_url, bird_image_port, url.QueryEscape(birdName)))
    if err != nil {
        return "", err
    }
    body, err := io.ReadAll(res.Body)
    return string(body), err
}

func getBirdFactoid() Bird {
	res, err := http.Get(fmt.Sprintf("%s%d", "https://freetestapi.com/api/v1/birds/", rand.IntN(50)))
	if err != nil {
		fmt.Printf("Error reading bird API: %s\n", err)
		return defaultBird(err)
	}
	body, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Printf("Error parsing bird API response: %s\n", err)
		return defaultBird(err)
	}
	var bird Bird
	err = json.Unmarshal(body, &bird)
	if err != nil {
		fmt.Printf("Error unmarshalling bird: %s", err)
		return defaultBird(err)
	}
    birdImage, err := getBirdImage(bird.Name)
    if err != nil {
        fmt.Printf("Error in getting bird image: %s\n", err)
        return defaultBird(err)
    }
    bird.Image = birdImage
	return bird
}

func bird(w http.ResponseWriter, r *http.Request) {
	var buffer bytes.Buffer
	json.NewEncoder(&buffer).Encode(getBirdFactoid())
	io.WriteString(w, buffer.String())
}

func main() {
	http.HandleFunc("/", bird)
	http.Handle("/metrics", promhttp.Handler())
	http.ListenAndServe(":4201", nil)
}
