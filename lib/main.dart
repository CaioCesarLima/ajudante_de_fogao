import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

void main() => runApp(MaterialApp(
    theme: ThemeData(
      scaffoldBackgroundColor: Colors.green[100],
      primaryColor: Colors.green,
    ),
    home: const MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
// Strings to store the extracted Article titles
  List<PostModel> results = [];
  String search = "";

// boolean to show CircularProgressIndication
// while Web Scraping awaits
  bool isLoading = false;

  Future<List<PostModel>> extractData(String search) async {
    // Getting the response from the targeted url
    final response = await http.Client().get(Uri.parse(
        'https://www.receitadahora.com/?s=${controller.text}&categoria=&tempo_praparo=&porcoes=&cozinha='));

    // Status Code 200 means response has been received successfully
    if (response.statusCode == 200) {
      // Getting the html document from the response
      var document = parser.parse(response.body);
      try {
        var result = document.getElementsByClassName('thumb-titulo');
        List<PostModel> posts = result.map((element) {
          return PostModel(element.text.trim(),
              element.children[0].attributes.values.toList()[1]);
        }).toList();

        return posts;
      } catch (e) {
        return [];
      }
    } else {
      return [];
    }
  }

  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajudante de Fogão'), actions: [
        MaterialButton(
          onPressed: () async {
            
            setState(() {
              results = [];
            });
          },
          child: const Text(
            'reset',
            style: TextStyle(color: Colors.white),
          ),
          color: Colors.green,
        )
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : results.isEmpty
                    ? Column(
                        children: [
                          Form(
                            child: TextField(
                              controller: controller,
                              
                              decoration: const InputDecoration(),
                            ),
                          ),
                          TextButton(
                              onPressed: () async {
                                setState(() {
                                    isLoading = true;
                                  });

                                  // Awaiting for web scraping function
                                  // to return list of strings
                                  final response = await extractData("");

                                  // Setting the received strings to be
                                  // displayed and making isLoading false
                                  // to hide the loader
                                  setState(() {
                                    results = response;
                                    isLoading = false;
                                    controller.clear();
                                  });
                              },
                              child: const Text("Pesquisar"))
                        ],
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: ((context, index) {
                          return GestureDetector(
                            onTap: (() {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Recipe(link: results[index].link)));
                            }),
                            child: ListTile(
                              title: Text(results[index].title),
                            ),
                          );
                        }))),
      ),
    );
  }
}

class PostModel {
  final String title;
  final String link;

  PostModel(this.title, this.link);
}

class Recipe extends StatefulWidget {
  final String link;

  const Recipe({
    Key? key,
    required this.link,
  }) : super(key: key);

  @override
  State<Recipe> createState() => _RecipeState();
}

class _RecipeState extends State<Recipe> {
  // while Web Scraping awaits
  bool isLoading = false;
  int step = 0;
  List<String> ingredientes = [];
  List<String> steps = [];
  int indexStep = 1;

  void incrementIndex() {
    if (step == 0 && indexStep < ingredientes.length - 2) {
      indexStep++;
    } else if (step == 0 && indexStep >= ingredientes.length - 2) {
      indexStep = 1;
      step = 1;
    } else if (step == 1 && indexStep < steps.length - 2) {
      indexStep++;
    } else {
      indexStep = 0;
      step = 0;
    }
  }

  Future<List<PostModel>> extractData() async {
    // Getting the response from the targeted url
    final response = await http.Client().get(Uri.parse(widget.link));

    // Status Code 200 means response has been received successfully
    if (response.statusCode == 200) {
      // Getting the html document from the response
      var document = parser.parse(response.body);
      try {
        // Scraping the first article title
        var ingredients =
            document.getElementsByClassName('receita-itens')[0].children[1];
        ingredients.nodes.forEach((element) {
          ingredientes.add(element.text!.trim());
        });

        var preparo =
            document.getElementsByClassName('receita-itens')[0].children[3];
        preparo.nodes.forEach((element) {
          steps.add(element.text!.trim());
        });

        return [];
      } catch (e) {
        return [];
      }
    } else {
      return [];
    }
  }

  void init() async {
    setState(() {
      isLoading = true;
    });
    await extractData();
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receita'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? const CircularProgressIndicator()
                : step == 0
                    ? listIngredientes()
                    : listSteps(),
            TextButton(
                onPressed: () {
                  setState(() {
                    incrementIndex();
                  });
                },
                child: const Text("Próximo passo"))
          ],
        ),
      ),
    );
  }

  Widget listIngredientes() {
    return Text(ingredientes[indexStep].toString());
  }

  Widget listSteps() {
    return Text(steps[indexStep].toString());
  }
}
