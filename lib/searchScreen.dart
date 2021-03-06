import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class SearchScreen extends StatefulWidget{

  final String _initialSearch;
  SearchScreen(this._initialSearch);

  @override
  State<StatefulWidget> createState() {
    return SearchScreenState(_initialSearch);
  }
}
class SearchScreenState extends State<SearchScreen>{

  String _searchquery;
  List<dynamic> results;
  bool isSearching=true;
  String title;
  List<int> selected = new List();

  SearchScreenState(searcgQuery){
    _searchquery=searcgQuery;
    title=searcgQuery;
    searchVid(_searchquery);
  }

  Widget body(){
    if(isSearching){
      return Center(child:CircularProgressIndicator());
    }
    else {
      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (BuildContext ctxt, int index){
          Color cardcolor;
          if(selected.contains(index)){
            cardcolor=Theme.of(context).highlightColor;
          }
          else{
            cardcolor=Theme.of(context).canvasColor;
          }
          return ListTile(
            title: Card(
              color: cardcolor,
              elevation: 6,
              margin: EdgeInsets.all(6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              child: InkWell(
                onTap: () async{
                  if(selected.isEmpty){


                    List<dynamic> returnValue = new List();
                    returnValue.add(results[index]);
                    setState(() {
                      isSearching=true;
                    });
                    List updatedreturnvalue = await resultSearchtoVideoHash(returnValue);
                    Navigator.pop(context,{'queue':updatedreturnvalue,'addtoexisting':false});
                  }
                  setState(() {
                    if(selected.isEmpty){

                    }
                    else{
                      if(selected.contains(index)){
                        selected.remove(index);
                        if(selected.isEmpty){
                          title=_searchquery;
                        }
                      }
                      else{
                        selected.add(index);
                        title=selected.length.toString();
                      }
                    }     
                  });
                  
                },
                onLongPress: (){
                  setState(() {
                    if(selected.contains(index))
                        selected.remove(index);
                    else
                      selected.add(index);
                    
                    if(selected.isEmpty){
                      title=_searchquery;
                    }
                    else{
                      title=selected.length.toString();
                    }
                    });
                  
                },
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedContainer(
                    duration: Duration(seconds: 3),
                    padding: EdgeInsets.all(10),
                    child: 
                    Image.network(getThumbnaillink(results, index, "videoThumbnails", "medium","quality"))
                  ,),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child:
                          Container(
                            padding: EdgeInsets.all(8),
                            child: Text(results[index]["title"],
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            ),
                          )
                      )
                    ],
                  )
                ],
              ),
              ),
            ),
          );
        },
      );
    }
  }





Future<dynamic> searchVid(searchquery) async {

    String apiurl="https://invidio.us/api/v1/search?q=";
    final response =
    await http.get(apiurl+ searchquery);

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      dynamic js = json.decode(response.body);
      setState(() {
              results=js;
              isSearching=false;
            });
      return js;
    } 
    else {
      print("Fetch ERROR");
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }

Future<List<dynamic>> resultSearchtoVideoHash(List vidlist) async {
  List<Map> newVidList = new List();
  for(Map x in vidlist){
    Map y = await fetchVid(x["videoId"]);
    newVidList.add(y);
  }
  return newVidList;
}

 Future<Map> fetchVid(id) async {

    String apiurl="https://invidio.us/api/v1/videos/";
    String videoId=id;
    final response = await http.get(apiurl+videoId);
    print("received");
    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      Map<String,dynamic> js = json.decode(response.body);
      
      return js;
    } else {
      print("Fetch ERROR");
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }


  @override
  Widget build(BuildContext context) {
    if(selected.isEmpty){
      title=_searchquery;
    }
    else{
      title=selected.length.toString();
    }
    return WillPopScope(
      onWillPop: (){
        return Future.value(selected.isEmpty);
      },
      child:Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          
          Opacity(
            opacity: selected.isEmpty?0:1,
            child: IconButton(
              icon: Icon(Icons.library_add),
              onPressed: () async {
                if(selected.isNotEmpty){
                  List<dynamic> returnValue = new List();
                  for(int x in selected){
                    returnValue.add(results[x]);
                  }
                  setState(() {
                                    isSearching=true;
                                  });
                  List updatedreturnvalue = await resultSearchtoVideoHash(returnValue);
                  Navigator.pop(context,{'queue':updatedreturnvalue,'addtoexisting':true});
                }
              },
            ),
          ),
          
          Opacity(
            opacity: selected.isEmpty?0:1,
            child:
          IconButton(
            onPressed: () async {
              if(selected.isNotEmpty){
                List<dynamic> returnValue = new List();
                for(int x in selected){
                  returnValue.add(results[x]);
                }
                setState(() {
                                  isSearching=true;
                                });
                List updatedreturnvalue = await resultSearchtoVideoHash(returnValue);
                Navigator.pop(context,{'queue':updatedreturnvalue,'addtoexisting':false});
              }
            },
            icon: Icon(Icons.play_arrow),
          )),
 
        ],
        title: Text(title),
        leading:
          IconButton(color: Colors.white,
          icon: Icon(Icons.arrow_back),
          onPressed: (){
            if(selected.length==0){
              Navigator.pop(context);
            }
            else{
              setState(() {
                              selected.clear();
                            });
            }
          },
          )
      ),
      body: body(),
      ),
    );
  }

}
String getThumbnaillink(List list,int index,String type ,dynamic quality, String finder){
    List result=list[index][type];
    for(int i=0;i<result.length;i++){
      if(result[i][finder]==quality){
        return result[i]["url"];
      }
    }
    return null;
}