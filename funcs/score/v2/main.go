package main

import (
	"io"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/zegl/kube-score/config"
	"github.com/zegl/kube-score/parser"
	"github.com/zegl/kube-score/renderer/human"
	"github.com/zegl/kube-score/score"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	t2html "github.com/buildkite/terminal-to-html"

	"github.com/fatih/color"
)

func handleRequest(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	fail := func(err error) events.APIGatewayProxyResponse {
		return events.APIGatewayProxyResponse{StatusCode: http.StatusBadRequest, Body: err.Error()}
	}

	cnf := config.Configuration{
		AllFiles: []io.Reader{
			strings.NewReader(req.Body),
		},
	}

	allObjs, err := parser.ParseFiles(cnf)
	if err != nil {
		return fail(err), nil
	}

	card, err := score.Score(allObjs, cnf)

	color.NoColor = false
	output := human.Human(card, 0, 110)

	body, _ := ioutil.ReadAll(output)

	htmlBody := t2html.Render(body)

	res := events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers: map[string]string{
			"Content-Type":                 "text/html",
			"Access-Control-Allow-Origin":  "*",
			"Access-Control-Allow-Methods": "OPTIONS,POST",
			"Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
		},
		Body: string(htmlBody),
	}
	return res, nil
}

func main() {
	lambda.Start(handleRequest)
}
