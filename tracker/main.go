package main

import (
	"context"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/seanhoughton/tracker/pkg/tracker"
	"gocv.io/x/gocv"
)

type Service struct {
	doc *tracker.Doc
}

func (s *Service) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	b, err := json.Marshal(s.doc)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	w.Header().Set("content-type", "application/json")
	w.Write(b)
}

func (s *Service) run(ctx context.Context, docs <-chan *tracker.Doc) {
	go func() {
		/*
			// open display window
			window := gocv.NewWindow("Face Detect")
			defer window.Close()
		*/

		// color for the rect when faces detected
		blue := color.RGBA{0, 0, 255, 0}

		for {
			select {
			case <-ctx.Done():
				return

			case doc := <-docs:
				log.Printf("Found %d items", len(doc.Items))

				s.doc = doc

				for _, item := range doc.Items {
					r := image.Rectangle{
						Min: image.Point{
							X: item.MinX,
							Y: item.MinY,
						},
						Max: image.Point{
							X: item.MaxX,
							Y: item.MaxY,
						},
					}
					gocv.Rectangle(&doc.Image, r, blue, 3)

					size := gocv.GetTextSize("Human", gocv.FontHersheyPlain, 1.2, 2)
					pt := image.Pt(item.MinX+(item.MinX/2)-(size.X/2), item.MinY-2)
					gocv.PutText(&doc.Image, "Human", pt, gocv.FontHersheyPlain, 1.2, blue, 2)
				}

				/*
					window.IMShow(doc.Image)
					if window.WaitKey(1) >= 0 {
						cancel()
					}
				*/
			}
		}
	}()
}

func main() {
	if len(os.Args) < 3 {
		fmt.Println("How to run:\n\ttracker [camera ID] [classifier XML file]")
		return
	}
	deviceID, _ := strconv.Atoi(os.Args[1])
	xmlFile := os.Args[2]
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	docs, errors := tracker.Track(ctx, deviceID, xmlFile, time.Second)

	service := &Service{}
	service.run(ctx, docs)

	go func() {
		for {
			select {
			case err := <-errors:
				log.Println(err)
				cancel()
			}
		}
	}()

	//http.Handle("/", service)
	err := http.ListenAndServe(":7777", service)
	log.Fatal(err)

}
