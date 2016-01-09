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

You just have to annotate properties with `@observable` and extend/mixin the familiar `Observable` mixin, exactly like before, and `polymer_autnotify` will take care of calling `polymer` accessor API 
 automatically for you.

To enable the autonotify feature just add the dependency to your project and add the mixin `AutonotifyBehavior` to your `PolymerElement` then 
annotate property with `@observable` (just like in the previous polymer version). 


## notes

Latest version of this library will not depend anymore on the old `smoke` mirroring system but requires a modified `observe` that you can find [here](https://github.com/dam0vm3nt/observe/tree/reflectable), 
 until the official one gets ported to reflectable or that branch gets merged.

## using the transformer 

This transfomer will replace `polymer-dart` one and adds support for observability.

Using this transformer you will not have to extend the `JsProxy` mixin or to annotate fields with `@reflectable` (see `polymer` docs) but instead you will have to use `Observable` mixin and `@observable` annotation (just like in the good ol' times):

```dart

class ThatBeautifulModelOfMine extends Observable {
 @observable String field1;
 @observable String field2;
}
```

All you have to do is to add it to your `pubspec.yaml` should appear like this :
```yaml
...

transformers:
 - autonotify_observe:
    entry_points:
    - web/index.html

...
```
`autonotify_observe` transformer should also be placed in all your dependency libs that defines custom `polymer` components using `autonotify` and/or exporting models object extending/mixing `Observe`.
