package main

import (
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"sync"
)

var (
	mutex   = &sync.Mutex{}
	count   = 0
	client  *http.Client
	locals  = [2]string{"0.0.0.0:1234", "0.0.0.0:1235"}
	dockers = [2]string{"172.17.0.1:1234", "172.17.0.1:1235"}
	ips     = [2]string{"192.168.1.7:1234", "192.168.1.7:1235"}
)

func httpHandler(w http.ResponseWriter, r *http.Request) {
	countMitigation()

	uri := "http://" + ips[count] + "/api/?key=1"

	res, err := client.Get(uri)

	if err != nil {
		log.Println("|", res.Status, "|", uri, "|", err)
	}

	defer res.Body.Close()

	io.Copy(w, res.Body)
}

func countMitigation() {
	mutex.Lock()

	if count == 1 {
		count--
	} else {
		count++
	}

	mutex.Unlock()
}

func definePort() string {
	portEnv := os.Getenv("PORT")

	if portEnv != "" {
		return ":" + portEnv
	}

	return ":8081"
}

func findMachineIP() string {
	addrs, err := net.InterfaceAddrs()

	if err != nil {
		return ""
	}

	for _, addr := range addrs {
		networkIP, ok := addr.(*net.IPNet)
		if ok && !networkIP.IP.IsLoopback() && networkIP.IP.To4() != nil {
			return networkIP.IP.String()
		}
	}

	return ""
}

func main() {
	transport := &http.Transport{
		MaxIdleConns:        1000,
		MaxIdleConnsPerHost: 1000,
	}

	client = &http.Client{Transport: transport}

	fmt.Println(findMachineIP())

	http.HandleFunc("/", httpHandler)
	log.Fatal(http.ListenAndServe(definePort(), nil))
}
