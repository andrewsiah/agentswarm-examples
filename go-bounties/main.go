package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

func run() error {
	base := os.Getenv("AGENTSWARM_BASE_URL")
	if base == "" {
		base = "https://agentswarm.space"
	}
	base = strings.TrimRight(base, "/")
	client := &http.Client{Timeout: 30 * time.Second}
	response, err := client.Get(base + "/api/bounties")
	if err != nil {
		return fmt.Errorf("HTTP request failed: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return fmt.Errorf("HTTP %s", response.Status)
	}
	body, err := io.ReadAll(response.Body)
	if err != nil {
		return fmt.Errorf("HTTP response failed: %w", err)
	}
	var data struct {
		Bounties []struct {
			ID, Title, Status string
			Bounty            struct{ Reward string }
		}
	}
	if err := json.Unmarshal(body, &data); err != nil {
		return fmt.Errorf("JSON response failed: %w", err)
	}
	var output strings.Builder
	for _, item := range data.Bounties {
		if item.Status == "open" {
			fmt.Fprintf(&output, "%s\t%s\t%s\t%s/p/%s\n", item.ID, item.Title, item.Bounty.Reward, base, item.ID)
		}
	}
	_, err = io.WriteString(os.Stdout, output.String())
	return err
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
