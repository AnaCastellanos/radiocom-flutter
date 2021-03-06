import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http_parser/src/media_type.dart';

enum HTTPMethod {
  GET,
  POST,
  PUT,
  DELETE
}

class SimpleRequest {
  final HTTPMethod method;
  final Uri url;
  final dynamic body;
  final Map<String, String> headers = new Map<String, String>();

  SimpleRequest(this.method, this.url,
      {this.body, Map<String, String> headers}) {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }
}

class SimpleClient {
  final Client client;

  SimpleClient({httpClient}) :
        client = httpClient == null ? new Client() : httpClient;

  dynamic getMethodCall(HTTPMethod method) {
    switch (method) {
      case HTTPMethod.POST:
        return this.client.post;
      case HTTPMethod.GET:
        return this.client.get;
      default:
        return this.client.get;
    }
  }

  Future<dynamic> get(Uri url, {Map<String, String> headers}) {
    return sendRequest(
        new SimpleRequest(
            HTTPMethod.GET,
            url,
            headers: headers
        )
    );
  }

  Future<dynamic> post(Uri url, { dynamic body, Map<String, String> headers}) {
    return sendRequest(
        new SimpleRequest(
          HTTPMethod.POST,
          url,
          body: body,
          headers: headers,
        )
    );
  }


  Future sendRequest(SimpleRequest request) {
    String reqBody = request.body != null
        ? JSON.encoder.convert(request.body)
        : null;

    Map<String, String> headers = {
      HttpHeaders.CONTENT_TYPE: 'application/json',
      HttpHeaders.ACCEPT_ENCODING: 'utf-8',
      HttpHeaders.ACCEPT_CHARSET : 'utf-8'
    };

    headers.addAll(request.headers);

    dynamic methodClient = getMethodCall(request.method);

    return processResponse(
        methodClient(
            request.url,
            headers: headers,
            //body: reqBody
        )
    );
  }

  Future processResponse(Future<Response> response) {
    return response
        .catchError((err) {
      throw new HttpException('Error sending request');
    })
        .then((Response response) {
      final statusCode = response.statusCode;

      if (statusCode < 200 || statusCode >= 300) {
        throw new HttpException(
            'Unexpected status code [$statusCode]: ${response.body}');
      }
      //decode due to a radioco problem with utf8 encoding
      var encoding = Encoding.getByName("utf-8");
      String responseUTF8 = encoding.decode(response.bodyBytes);

      dynamic respBody = JSON.decode(responseUTF8);

      if (respBody == null) {
        throw new HttpException('Error parsing response');
      }

      return respBody;
    });
  }

}
