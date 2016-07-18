@TestOn('browser')
library polymer_autonotify.tests;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:test/test.dart';

import "package:web_components/web_components.dart" show HtmlImport;
import "package:observe/observe.dart";
import "package:polymer_autonotify/polymer_autonotify.dart";

import "package:logging/logging.dart";

import "dart:js";

TestMain element;
TestElement subElement1;
TestElement subElement2;

int counter = 0;

main() async {
  await initPolymer();

  setUp(() {
    element = document.createElement('test-main');
    //document.body.append(element);
    List<Element> subs = Polymer.dom(element.root).querySelectorAll("test-element");
    subElement1 = subs[0];
    subElement2 = subs[1];
  });

  test('sanity check', () {
    expect(element, isNotNull);
    expect(subElement1, isNotNull);
    expect(subElement2, isNotNull);
    expect(element.myModel, isNotNull);
  });

  group('poly model', () {
    test("check1", () async {
      element.field1 = "newVal";
      await miracle();
      expect(subElement2.message2, "newVal");
    });
  });

  group('generic tests', () {
    test('add elements', () async {
      //element.add("samples",new Sample("X","Y"));

      element.samples.add(new Sample("X1", "Y1"));
      element.samples.add(new Sample("X2", "Y2"));
      element.samples.add(new Sample("X3", "Y3"));
      await miracle();
      //await new Future.value(true);
      DivElement elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='0']");
      //print(subElement1.outerHtml);
      expect(elem1, isNotNull);
      expect(elem1.attributes["f1"], "X1");
      expect(elem1.attributes["f2"], "Y1");

      DivElement elem2 = Polymer.dom(subElement2.root).querySelector("[data-marker='1']");
      //print(subElement1.outerHtml);
      expect(elem2, isNotNull);
      expect(elem2.attributes["f1"], "X2");
      expect(elem2.attributes["f2"], "Y2");
    });

    test('update element', () async {
      List<Sample> mySamples = new ObservableList();
      element.samples = mySamples;
      Sample s1 = new Sample("X", "Y");
      Sample s2 = new Sample("A", "C");

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNull);

      mySamples.add(s1);

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNotNull);
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNull);

      mySamples.add(s2);

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNotNull);
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNotNull);

      s2.field1 = "alpha1";

      await miracle();
      DivElement elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='1']");
      expect(elem1.attributes["f1"], "alpha1");
      expect(elem1.attributes["f2"], "C");
    });

    test('replace element', () async {
      List<Sample> mySamples = new ObservableList();
      element.samples = mySamples;
      Sample s1 = new Sample("X", "Y");
      Sample s2 = new Sample("A", "C");

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNull);

      mySamples.add(s1);

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNotNull);
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNull);

      mySamples.add(s2);

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNotNull);
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNotNull);
      DivElement elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='1']");
      expect(elem1.attributes["f1"], "A");
      expect(elem1.attributes["f2"], "C");

      mySamples[1] = new Sample("alpha1", "alpha2");

      await miracle();
      elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='1']");
      expect(elem1.attributes["f1"], "alpha1");
      expect(elem1.attributes["f2"], "alpha2");
    });

    test('insert element', () async {
      List<Sample> mySamples = new ObservableList();
      element.samples = mySamples;
      Sample s1 = new Sample("X", "Y");
      Sample s2 = new Sample("A", "C");

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNull);

      mySamples.add(s1);

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNotNull);
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNull);

      mySamples.add(s2);

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNotNull);
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNotNull);
      DivElement elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='1']");
      expect(elem1.attributes["f1"], "A");
      expect(elem1.attributes["f2"], "C");

      mySamples.insert(1, new Sample("alpha1", "alpha2"));

      await miracle();
      elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='1']");
      expect(elem1.attributes["f1"], "alpha1");
      expect(elem1.attributes["f2"], "alpha2");
      elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='2']");
      expect(elem1.attributes["f1"], "A");
      expect(elem1.attributes["f2"], "C");
    });

    test('remove element', () async {
      List<Sample> mySamples = new ObservableList();
      element.samples = mySamples;
      Sample s1 = new Sample("X", "Y");
      Sample s2 = new Sample("A", "C");

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNull);

      mySamples.add(s1);

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNotNull);
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNull);

      mySamples.add(s2);

      await miracle();
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='0']"), isNotNull);
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNotNull);
      DivElement elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='1']");
      expect(elem1.attributes["f1"], "A");
      expect(elem1.attributes["f2"], "C");

      mySamples.remove(s1);

      await miracle();
      elem1 = Polymer.dom(subElement1.root).querySelector("[data-marker='0']");
      expect(elem1.attributes["f1"], "A");
      expect(elem1.attributes["f2"], "C");
      expect(Polymer.dom(subElement1.root).querySelector("[data-marker='1']"), isNull);
    });
  });

  test('pseudo shuffle elements', () async {
    Sample s1 = new Sample("X", "Y");
    Sample s2 = new Sample("A", "C");
    Sample s3 = new Sample("B", "C");
    Sample s4 = new Sample("C", "C");
    Sample s5 = new Sample("D", "C");
    Sample s6 = new Sample("E", "C");
    Sample s7 = new Sample("F", "C");
    Sample s8 = new Sample("G", "C");
    Sample s9 = new Sample("H", "C");
    List<Sample> mySamples = new ObservableList.from([s1, s2, s3, s4, s5, s6, s7, s8, s9]);
    element.samples = mySamples;
    await miracle();

    mySamples.insertAll(0, [s6, s4]);
    //   await miracle();
    mySamples.insertAll(3, [s9]);
    //   await miracle();
    mySamples.removeRange(5, 7);
    mySamples.insertAll(5, [s8]);

    await miracle();
  });

  test('pseudo shuffle elements2', () async {
    Sample s1 = new Sample("X", "Y");
    Sample s2 = new Sample("A", "C");
    Sample s3 = new Sample("B", "C");
    Sample s4 = new Sample("C", "C");
    Sample s5 = new Sample("D", "C");
    Sample s6 = new Sample("E", "C");
    Sample s7 = new Sample("F", "C");
    Sample s8 = new Sample("G", "C");
    Sample s9 = new Sample("H", "C");
    List<Sample> mySamples = new ObservableList.from([s1, s2, s3, s4, s5, s6, s7, s8, s9]);
    element.samples = mySamples;
    await miracle();

//    mySamples.insertAll(0,[s6,s4]);
    //   await miracle();
    //   mySamples.insertAll(3,[s9]);
    //   await miracle();
    mySamples.removeRange(5, 6);
    mySamples.insertAll(5, [s8, s9]);

    await miracle();
  });

  test('compute message', () async {
    element.message = "test1";
    await miracle();
    expect(element.computedMessage, "Computed test1");
    DivElement dv = Polymer.dom(element.root).querySelector("#computedDiv");
    expect(dv, isNotNull);
    expect(dv.attributes["computed-attr"], "Computed test1");
  });

  test('pseudo shuffle elements3', () async {
    Sample s1 = new Sample("X", "Y");
    Sample s2 = new Sample("A", "C");
    Sample s3 = new Sample("B", "C");
    Sample s4 = new Sample("C", "C");
    Sample s5 = new Sample("D", "C");
    Sample s6 = new Sample("E", "C");
    Sample s7 = new Sample("F", "C");
    Sample s8 = new Sample("G", "C");
    Sample s9 = new Sample("H", "C");
    List<Sample> mySamples = new ObservableList.from([s1, s2, s3, s4, s5, s6, s7, s8, s9]);
    element.samples = mySamples;
    await miracle();

//    mySamples.insertAll(0,[s6,s4]);
    //   await miracle();
    //   mySamples.insertAll(3,[s9]);
    //   await miracle();

    print("Initial : ${mySamples}");

    mySamples.removeRange(1, 3);
    mySamples.insertAll(2, [s7, s6]);
    mySamples.removeRange(5, 7);
    mySamples.insertAll(5, [s2, s3]);

    print("Final : ${mySamples}");

    await miracle();
  });

  test('autoref model - no autonotify', () async {
    TestElementNoAuto el = new TestElementNoAuto();

    AutoRefModelNoAuto m = new AutoRefModelNoAuto();
    el.set('autoRefModel2', m);

    await miracle();
    el.set('autoRefModel2.autoRef', m);

    await miracle();

    el.set('autoRefModel2.name','ciccio');

    await miracle();

    DivElement dv = el.$['name'];

    DivElement dv2 = el.$['name2'];
    expect(dv.text,'ciccio',reason:"notification worked");
    expect(dv2.text,'',reason:"no recursive notification");


    el.set('autoRefModel2.autoRef',null);

    expect(dv.text,'ciccio',reason:"notification worked");
    expect(dv2.text,'',reason:"notification worked - recurr");


    await miracle();
  });


  test('autoref model', () async {
    TestElement el = new TestElement();

    AutoRefModel m = new AutoRefModel();
    el.autoRefModel = m;

    await miracle();
    m.autoRef = m;

    await miracle();

    m.name = "ciccio";

    await miracle();

    DivElement dv = el.$['name'];

    DivElement dv2 = el.$['name2'];
    expect(dv.text,'ciccio',reason:"notification worked");
    expect(dv2.text,'',reason:"no recursive notification");

    m.autoRef = null;

    expect(dv.text,'ciccio',reason:"notification worked");
    expect(dv2.text,'',reason:"notification worked - recurr");


    await miracle();
  });

  test('autoref model - indirect recursion', () async {
    TestElement el = new TestElement();

    AutoRefModel m = new AutoRefModel();
    el.autoRefModel = m;


    await miracle();
    AutoRefModel m1 = new AutoRefModel();
    m.autoRef = m1;

    await miracle();

    m1.autoRef = m;

    await miracle();


    m.name = "ciccio";

    await miracle();
    m1.name = "ciccio";

    await miracle();


    DivElement dv = el.$['name'];

    DivElement dv2 = el.$['name2'];
    expect(dv.text,'ciccio',reason:"notification worked");
    expect(dv2.text,'ciccio',reason:"no recursive notification");

    m.autoRef = null;
    await miracle();

    expect(dv.text,'ciccio',reason:"notification worked");
    expect(dv2.text,'',reason:"notification worked - recurr");


    await miracle();
  });

  test('shuffle elements', () async {
    List<Sample> mySamples = new ObservableList.from([
      new Sample("X", "Y"),
      new Sample("A", "C"),
      new Sample("B", "C"),
      new Sample("C", "C"),
      new Sample("D", "C"),
      new Sample("E", "C"),
      new Sample("F", "C"),
      new Sample("G", "C"),
      new Sample("H", "C")
    ]);
    element.samples = mySamples;
    await miracle();

    for (int i = 0; i < 1000; i++) {
      // print("Shuffle ${i} begin");
      mySamples.shuffle();
      // print("Shuffle ${i} end - await");
      await miracle();
      // print("Shuffle ${i} end - done");
    }
  });
}

Future miracle() => new Future.delayed(new Duration(milliseconds: 0));

class AutoRefModel extends Observable {
  @observable
  String name;
  @observable
  var autoRef;
}

class AutoRefModelNoAuto extends JsProxy with ChangeNotifier {
  @reflectable
  String name;
  @reflectable
  AutoRefModelNoAuto autoRef;
}

class Sample extends Observable {
  @observable
  String field1;
  @observable
  String field2;

  Sample(this.field1, this.field2);

  String toString() => "S(${field1};${field2})";
}

@PolymerRegister('test-no-auto')
class TestElementNoAuto extends PolymerElement {

  @property
  AutoRefModelNoAuto autoRefModel;

  @Observe('autoRefModel.*')
  void changedSomething(_) {
    print("Changed : ${_}");
  }

  TestElementNoAuto.created() : super.created();

  factory TestElementNoAuto() => new Element.tag('test-no-auto');
}

@PolymerRegister("test-element")
class TestElement extends PolymerElement with Observable, AutonotifyBehavior {
  static final Logger _logger = new Logger("test.element.TestElement");

  @observable
  @property
  AutoRefModel autoRefModel;

  @observable
  @property
  List<Sample> samples;

  @observable
  @Property(notify: true)
  String message;

  @observable
  @Property(notify: true)
  String message2;

  TestElement.created() : super.created() {
    //  PolymerAutoNotifySupportJsBehavior, PolymerAutoNotifySupportBehavior.created(this);
  }

  factory TestElement() => (new Element.tag("test-element") as TestElement);
}

class Holder extends Observable {
  @observable
  String message = "OK";
  Holder(this.message);
}

@PolymerRegister("sample-model")
class SampleModel extends PolymerElement with Observable, AutonotifyBehavior {
  SampleModel.created() : super.created();

  @observable
  @Property(notify: true)
  String myField;
}

@PolymerRegister("test-main")
class TestMain extends PolymerElement with Observable, PolymerAutoNotifySupportJsBehavior, PolymerAutoNotifySupportBehavior {
  static final Logger _logger = new Logger("test.element.TestMain");

  @observable
  @property
  List<Sample> samples = new ObservableList();
  @observable
  @Property(notify: true)
  String message = "OK";

  //@observable
  @Property(computed: 'computeMe(message)')
  String computedMessage;

  @reflectable
  String computeMe(String message) => "Computed $message";

  @observable
  @Property(notify: true)
  Holder message2 = new Holder("KO");
  @observable
  @Property(notify: true)
  String field1;

  @observable
  @property
  SampleModel myModel;
  @property
  int step = 1;

  void ready() {
    myModel = $["XYZ"];
  }

  @reflectable
  String clickMe([_, __]) {
    print("CLICKED");
    samples.insert(1, new Sample("ciao${counter++}", "ciao${counter++}"));
  }

  @reflectable
  void removeMe([_, __]) {
    if (samples.isNotEmpty) {
      samples.removeAt(0);
    }
  }

  @reflectable
  void removeMe2([_, __]) {
    removeAt("samples", 0);
  }

  @reflectable
  void addInitial([_, __]) {
    samples.addAll([new Sample("1,1", "1,2"), new Sample("2,1", "2,2")]);
  }

  @reflectable
  void updateMe([_, __]) {
    samples[1].field1 = "CHANGED";
    print("CHANGED");
  }

  @reflectable
  void updateMe2([_, __]) {
    set("samples.1.field1", "CHANGED");
  }

  @reflectable
  void addEnd([_, __]) {
    samples.add(new Sample(message, message2.message));
  }

  @reflectable
  void addEnd2([_, __]) {
    add("samples", new Sample("ciao${counter++}", "ciao${counter++}"));
  }

  @reflectable
  void removeEnd([_, __]) {
    samples.removeLast();
  }

  @Observe("samples.splices")
  void samplesChanged(splices) {
    _logger.fine("SAMPLES CHANGED :${splices}");
  }

  @reflectable
  void replaceOne([_, __]) {
    samples[1] = new Sample("REPLACED", "REPLACED");
  }

  @reflectable
  void testSome([_, __]) {
    var list = new ObservableList.from(["a", "b", "c"])
      ..listChanges.listen((List<ListChangeRecord> changes) {
        changes.forEach((ListChangeRecord rec) {
          print("CHANGED :${rec}");
        });
      });
    JsArray js = new JsArray.from(list);
    js.callMethod("splice", [1, 0, "d"]);
    print("JS FINAL : ${js}");
    print("LIST FINALE :${list}");
  }

  @reflectable
  void addMe2([_, __]) {
    insert("samples", 1, new Sample("banana-${counter++}", "papaghena-${counter++}"));
  }

  @reflectable
  void doMany([_, __]) {
    [() => addEnd2(), () => addEnd2(), () => addEnd2(), () => updateMe2(), () => removeMe2(), () => updateMe2()][step - 1]();

    set("step", step + 1);
  }

  TestMain.created() : super.created() {
    // PolymerAutoNotifySupportJsBehavior, PolymerAutoNotifySupportBehavior.created(this);
  }

  factory TestMain() => (new Element.tag("test-main") as TestMain);
}
