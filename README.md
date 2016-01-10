# Auto notify support for (yet to be released) polymer-dart 1.0
a.k.a. : get rid of all those fancy `set`, `add`, `remove`, etc. calls


## the problem 

In `polymer` 1.0 you have to call a bunch of API (`set` and list accessor methods) on the polymer component whenever you have to apply a change on the model instead of changing the model directly. To make things worse if you have
two or more independent components, for example two different views of the same model that are not inheriting the model one from the other by means of binding constructs (i.e. `{{ }}` or
 `[[ ]]`), then you will have to call those API on each of component.
 
Other then being very annoying this makes nearly impossible to follow consolidated patterns like MVC when building an app using vanilla polymer 1.0 : 
infact the controller (C) should always interact directly with the view (V) to update the model (M).

The opposite is true for `polymer` before 1.0 and that's one of the reason many appreciated that framework even though it was slower and less browser independent.

## enters `autonotify`

This package will add support for autonotify in polymer-dart 1.0, making it possible to write your code more or less in the same way you used to do with previous `polymer` version.

## how it works

You just have to annotate properties with `@observable` and extend/mixin the familiar `Observable` mixin, exactly like for previous `polymer` version, and `polymer_autnotify` will take care of calling `polymer` accessor API 
 automatically for you.
 
### The model
 
Any class you intend to use as a model object should be extend or mixin `Observable`. Any property you want to be available for unidirectional or bidirectional binding should be annotatated by `@observable`. For example:

```dart

import "package:observe/observe.dart";

class MyModel extends Observable {
 @observable String field1;
 @observable AnotherModel field2;
}

class AnotherModel extends Object with Observable {
 @observable String field3;
}

```

### The element

Your `polymer` element should be defined as usual and mixin both `AutonotifyBehavior` and  `Observable`, properties should be annotated both with `@observable` and `@property` (or `@Property(...)`). Use `ObservableList` for mutable collections :

```dart
...
import "package:polymer_autonotify/polymer_autonotify.dart" show AutonotifyBehavior;

@PolymerRegister("my-element")
class MyElement extends PolymerElement with AutonotifyBehavior,Observable {
 @observable @property List<MyModel> prop1  = new ObservableList();
 @observable @property String prop2;
 
 
 MyElement.created() : super.created();

 @reflectable
 void doChange1([_,__]) {
  prop1.add(new MyModel());
 }
 
 @reflectable
 void doChange2([ev,__]) {
   new DomRepeatModel.fromEvent(convertFromJs(ev))["item"].field2="hello!";
 }

}

```

Notice : you do not have to call list API accessor neither `set` method, just update the model and the bidings will get updated, but this should not be a big surprise after all it is all this package is all about.

### using the transformer 

To enable observability you have to add the `autonotify_observe` transformer to all you dart project that are using it (both your main application and any other libraries that your main application depends on and that will define model classes and/or polymer elements).

The transformer can be used in place of the `polymer` transformer, in that case your `pubspec.yaml` will be simple and like this:

```yaml
...
transformers:
 - autonotify_observe:
    entry_points:
    - web/index.html

...
```
(entry points are those defined by the `polymer` transformer, see `polymer` documentations for that).

If you prefer to use the original `polymer` transformer then you can (as a matter of fact at the moment there is no reason for doing that, but anyway the choice is yours). In this case your `pubspec.yaml` should be like this:

```yaml
...
transformers:
 - autonotify_observe
 - polymer:
    entry_points:
    - web/index.html

...
```
Just avoid to specify any `entry_point` for the `autonotify_observe` and enlist that transformer before `polymer` one.

As already stated before if your main app imports models classes or elements from other packages then you should declare the `autonotify_observe` also in the corresponding `pubspec.yaml`, like this:

```yaml
...
transformers:
 - autonotify_observe
...
```

## notes

`autonotify_observe` requires a modified `observe` library that you can find [here](https://github.com/dam0vm3nt/observe/tree/reflectable).
You do not have to explicitly declare a dependency because you will implicitly get it as a dependency of this package.

