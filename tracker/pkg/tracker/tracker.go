package tracker

import (
	"context"
	"fmt"
	"log"
	"time"

	"gocv.io/x/gocv"
)

type Item struct {
	MinX int `json:"min_x"`
	MaxX int `json:"max_x"`
	MinY int `json:"min_y"`
	MaxY int `json:"max_y"`
}

type Screen struct {
	Width  int `json:"width"`
	Height int `json:"height"`
}

type Doc struct {
	Image  gocv.Mat `json:"-"`
	Screen Screen   `json:"screen"`
	Items  []Item   `json:"items"`
}

func Track(ctx context.Context, deviceID int, classifierXML string, interval time.Duration) (<-chan *Doc, <-chan error) {
	docs := make(chan *Doc)
	errors := make(chan error)

	log.Printf("start reading camera device: %v\n", deviceID)
	go func() {
		defer close(docs)
		defer close(errors)

		// open webcam
		webcam, err := gocv.VideoCaptureDevice(deviceID)
		if err != nil {
			errors <- err
			return
		}
		defer webcam.Close()
		log.Printf("video capture started")

		// load classifier to recognize faces
		classifier := gocv.NewCascadeClassifier()
		defer classifier.Close()
		if !classifier.Load(classifierXML) {
			errors <- fmt.Errorf("error reading cascade file: %v", classifierXML)
			return
		}
		log.Printf("loaded classifier [%s]", classifierXML)

		// prepare image matrix
		img := gocv.NewMat()
		defer img.Close()

		for {
			select {
			case <-ctx.Done():
				return
			default:
				if ok := webcam.Read(&img); !ok {
					log.Printf("cannot read device %d\n", deviceID)
					time.Sleep(interval)
					continue
				}
				if img.Empty() {
					log.Printf("image was empty\n")
					time.Sleep(interval)
					continue
				}

				// detect faces
				rects := classifier.DetectMultiScale(img)
				log.Printf("found %d faces\n", len(rects))

				dims := img.Size()

				doc := &Doc{
					Screen: Screen{
						Width:  dims[0],
						Height: dims[1],
					},
					Image: img.Clone(),
				}

				for _, r := range rects {
					doc.Items = append(doc.Items, Item{MinX: r.Min.X, MaxX: r.Max.X, MinY: r.Min.Y, MaxY: r.Max.Y})
				}

				docs <- doc

				time.Sleep(interval)
			}
		}
	}()

	return docs, errors
}
