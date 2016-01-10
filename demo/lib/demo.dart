@HtmlImport("demo.html")
library polymer_autonotify.demo;

import "package:polymer/polymer.dart";
import "package:web_components/web_components.dart" show HtmlImport;
import "package:polymer_autonotify/polymer_autonotify.dart";
import "package:observe/observe.dart";

import "package:polymer_elements/paper_item.dart";
import "package:polymer_elements/paper_input.dart";
import "package:polymer_elements/paper_icon_button.dart";
import "package:polymer_elements/paper_button.dart";
import "package:polymer_elements/iron_icons.dart";

import "dart:html";

class MyItem extends Observable {
 @observable String name;
 @observable String value;

 MyItem({this.name,this.value});
}

@PolymerRegister("test-polymer-autonotify")
class TestPolymerAutonotify extends PolymerElement with AutonotifyBehavior, Observable {
 
 @observable @property List items = new ObservableList();
 
 @observable @property String newName;
 @observable @property String newValue;

 @reflectable
 void addItem([_,__]) {
  items.add(new MyItem(name:newName,value:newValue));
 }

 @reflectable
 void removeItem(Event ev,[_]) {
  DomRepeatModel m = new DomRepeatModel.fromEvent(convertToJs(ev));

  items.remove(m["item"]);
 }

 @reflectable
 void doShuffle([_,__]) {
  items.shuffle();
 }

 TestPolymerAutonotify.created() : super.created();
}
