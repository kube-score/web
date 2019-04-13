package main

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"

	"github.com/zegl/kube-score/config"
	"github.com/zegl/kube-score/parser"
	"github.com/zegl/kube-score/score"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
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

	cardJson, err := json.Marshal(card)
	if err != nil {
		return fail(err), nil
	}

	res := events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers: map[string]string{
			"Content-Type":                 "application/json; charset=utf-8",
			"Access-Control-Allow-Origin":  "*",
			"Access-Control-Allow-Methods": "OPTIONS,POST",
			"Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
		},
		Body: string(cardJson),
	}
	return res, nil
}

func main() {
	lambda.Start(handleRequest)
}
