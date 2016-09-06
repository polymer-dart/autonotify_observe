@HtmlImport("demo.html")
library polymer_autonotify.demo;

import "package:polymer/polymer.dart";
import "package:web_components/web_components.dart" show HtmlImport;
import "package:autonotify_observe/autonotify_observe.dart";

import "package:polymer_elements/paper_item.dart";
import "package:polymer_elements/paper_input.dart";
import "package:polymer_elements/paper_icon_button.dart";
import "package:polymer_elements/paper_button.dart";
import "package:polymer_elements/iron_icons.dart";
import 'package:custom_elements/iron_data_table.dart';
import 'package:custom_elements/data_table_column.dart';
import 'package:custom_elements/iron_data_table_style.dart';

import "dart:html";

class MyItem extends Observable {
  @observable
  String name;
  @observable
  String value;

  MyItem({this.name, this.value});
}

@PolymerRegister("test-polymer-autonotify")
class TestPolymerAutonotify extends PolymerElement
    with AutonotifyBehavior, Observable {
  @observable
  @property
  List items = new ObservableList();

  @observable
  @property
  String newName;
  @observable
  @property
  String newValue;

  @observable
  @property
  var data = [
    {
      "name": {"title": "miss", "first": "donna", "last": "davis"}
    },
    {
      "name": {"title": "mr", "first": "samuel", "last": "kelley"}
    },
    {
      "name": {"title": "ms", "first": "katie", "last": "butler"}
    }
  ];

  @reflectable
  void addItem([_, __]) {
    items.add(new MyItem(name: newName, value: newValue));
  }

  @reflectable
  void addItemOld([_, __]) {
    add('items', new MyItem(name: newName, value: newValue));
  }

  @Observe('items.splices')
  void changedItems(_) {
    print("CHANGED ITEMS : ${_}");
  }

  @reflectable
  void removeMyItem(Event ev, [_]) {
    DomRepeatModel m = new DomRepeatModel.fromEvent(convertToJs(ev));

    items.remove(m["item"]);
  }

  @reflectable
  void doShuffle([_, __]) {
    items.shuffle();
  }

  TestPolymerAutonotify.created() : super.created();
}
