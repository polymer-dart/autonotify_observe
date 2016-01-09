// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Code transform for @observable. The core transformation is relatively
/// straightforward, and essentially like an editor refactoring.
library draft.polymer.autonotify.transformer;

import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/messages/build_logger.dart';
import 'package:source_maps/refactor.dart';
import 'package:source_span/source_span.dart';

/// A [Transformer] (fully borrowed from `observe` transformer)
/// that will add "JsProxy" and "@reflectabe" to object decorated with "Observe" and "@obserable"
/// to simplfy life of people.
/// This is intended to be run BEFORE observe transformer.
///
class AutonotifyTransformer extends Transformer {
  final bool releaseMode;
  final bool injectBuildLogsInOutput;
  final List<String> _files;
  AutonotifyTransformer(
      {List<String> files, bool releaseMode, bool injectBuildLogsInOutput})
      : _files = files,
        releaseMode = releaseMode == true,
        injectBuildLogsInOutput = injectBuildLogsInOutput == null
            ? releaseMode != true
            : injectBuildLogsInOutput;
  AutonotifyTransformer.asPlugin(BarbackSettings settings)
      : _files = _readFiles(settings.configuration['files']),
        releaseMode = settings.mode == BarbackMode.RELEASE,
        injectBuildLogsInOutput = settings.mode != BarbackMode.RELEASE;

  static List<String> _readFiles(value) {
    if (value == null) return null;
    var files = [];
    bool error;
    if (value is List) {
      files = value;
      error = value.any((e) => e is! String);
    } else if (value is String) {
      files = [value];
      error = false;
    } else {
      error = true;
    }
    if (error) print('Invalid value for "files" in the observe transformer.');
    return files;
  }

  // TODO(nweiz): This should just take an AssetId when barback <0.13.0 support
  // is dropped.
  Future<bool> isPrimary(idOrAsset) {
    var id = idOrAsset is AssetId ? idOrAsset : idOrAsset.id;
    return new Future.value(id.extension == '.dart' &&
        (_files == null || _files.contains(id.path)));
  }

  Future apply(Transform transform) {

    return transform.primaryInput.readAsString().then((content) {
      // Do a quick string check to determine if this is this file even
      // plausibly might need to be transformed. If not, we can avoid an
      // expensive parse.
      if (!observableMatcher.hasMatch(content)) return null;

      var id = transform.primaryInput.id;
      // TODO(sigmund): improve how we compute this url
      var url = id.path.startsWith('lib/')
          ? 'package:${id.package}/${id.path.substring(4)}'
          : id.path;
      var sourceFile = new SourceFile(content, url: url);
      var logger = new BuildLogger(transform,
          convertErrorsToWarnings: !releaseMode,
          detailsUri: 'http://goo.gl/5HPeuP');
      var transaction = _transformCompilationUnit(content, sourceFile, logger);
      if (!transaction.hasEdits) {
        transform.addOutput(transform.primaryInput);
      } else {
        var printer = transaction.commit();
        // TODO(sigmund): emit source maps when barback supports it (see
        // dartbug.com/12340)
        printer.build(url);
        transform.addOutput(new Asset.fromString(id, printer.text));
      }

      if (injectBuildLogsInOutput) return logger.writeOutput();
    });
  }
}

TextEditTransaction _transformCompilationUnit(
    String inputCode, SourceFile sourceFile, BuildLogger logger) {
  var unit = parseCompilationUnit(inputCode, suppressErrors: true);
  var code = new TextEditTransaction(inputCode, sourceFile);
  for (var directive in unit.directives) {
    if (directive is LibraryDirective && _hasObservable(directive)) {
      logger.warning(NO_OBSERVABLE_ON_LIBRARY,
          span: _getSpan(sourceFile, directive));
      break;
    }
  }


  // TODO(dam0vm3nt) Ad import to polymer if there is not yet
  // add import of polymer with prefix and change the code to use that prefix
  // show only reflectable and JsProxy
  int pos =unit.offset;
  ImportDirective first = unit.directives.firstWhere((x) => x is ImportDirective,orElse:()=>null);
  if (first!=null) {
    pos=first.offset;
  }
/*
  bool hasAlreadyPolymer = unit.directives.any((x) => (x is ImportDirective) && (x as ImportDirective).uri.toString().contains("polymer/polymer.dart"));

  if (!hasAlreadyPolymer&&(first!=null||!unit.directives.any((x) => x is PartOfDirective))) {
    // Check if this is a part ..
    code.edit(pos, pos, "import 'package:polymer/polymer.dart';");

  }
*/
  for (var declaration in unit.declarations) {
    if (declaration is ClassDeclaration) {
      _transformClass(declaration, code, sourceFile, logger);
    } else if (declaration is TopLevelVariableDeclaration) {
      if (_hasObservable(declaration)) {
        logger.warning(NO_OBSERVABLE_ON_TOP_LEVEL,
            span: _getSpan(sourceFile, declaration));
      }
    }
  }
  return code;
}

_getSpan(SourceFile file, AstNode node) => file.span(node.offset, node.end);

/// True if the node has the `@observable` or `@published` annotation.
// TODO(jmesserly): it is not good to be hard coding Polymer support here.
bool _hasObservable(AnnotatedNode node) =>
    node.metadata.any(_isObservableAnnotation) && node.metadata.every(_isNotPropertyAnnotation);

// TODO(jmesserly): this isn't correct if the annotation has been imported
// with a prefix, or cases like that. We should technically be resolving, but
// that is expensive in analyzer, so it isn't feasible yet.
bool _isObservableAnnotation(Annotation node) =>
    _isAnnotationContant(node, 'observable') ||
        _isAnnotationType(node, 'ObservableProperty');

bool _isNotPropertyAnnotation(Annotation node) =>
  !_isAnnotationContant(node,"property") &&
  !_isAnnotationContant(node,"reflectable") &&
  !_isAnnotationType(node,"Property") &&
  !_isAnnotationType(node,"PolymerReflectable");

bool _isAnnotationContant(Annotation m, String name) =>
    m.name.name == name && m.constructorName == null && m.arguments == null;

bool _isAnnotationType(Annotation m, String name) => m.name.name == name;

void _transformClass(ClassDeclaration cls, TextEditTransaction code,
    SourceFile file, BuildLogger logger) {
  if (_hasObservable(cls)) {
    logger.warning(NO_OBSERVABLE_ON_CLASS, span: _getSpan(file, cls));
  }


  // We'd like to track whether observable was declared explicitly, otherwise
  // report a warning later below. Because we don't have type analysis (only
  // syntactic understanding of the code), we only report warnings that are
  // known to be true.
  if (cls.extendsClause != null) {
    var id = _getSimpleIdentifier(cls.extendsClause.superclass.name);
    if (id.name == 'Observable') {
      if (cls.withClause==null) {
        code.edit(id.offset, id.end, '/*X*/ JsProxy with Observable');
      } else {
        code.edit(cls.withClause.mixinTypes[0].offset,cls.withClause.mixinTypes[0].offset,"/*Y*/ JsProxy,");
      }
    }
  }

  if (cls.withClause != null) {
    for (var type in cls.withClause.mixinTypes) {
      var id = _getSimpleIdentifier(type.name);
      if (id.name == 'Observable') {
        if (_getSimpleIdentifier(cls.extendsClause.superclass.name)!='PolymerElement') {
          code.edit(id.offset, id.offset, '/*Z*/ JsProxy,');
        }
      } else if (id.name == 'ChangeNotifier') {
        break;
      }
    }
  }


  // Track fields that were transformed.
  var instanceFields = new Set<String>();

  for (var member in cls.members) {
    if (member is FieldDeclaration) {
      if (member.isStatic) {
        continue;
      }
      if (_hasObservable(member)) {
        _transformFields(file, member, code, logger);

      }
    } else if ( (member is MethodDeclaration) && ( member.isGetter||member.isSetter) ) {
      _transformGetter(file,member,code,logger);
    }


  }

}

SimpleIdentifier _getSimpleIdentifier(Identifier id) =>
    id is PrefixedIdentifier ? id.identifier : id;

bool _hasKeyword(Token token, Keyword keyword) =>
    token is KeywordToken && token.keyword == keyword;

String _getOriginalCode(TextEditTransaction code, AstNode node) =>
    code.original.substring(node.offset, node.end);

bool _isReadOnly(VariableDeclarationList fields) {
  return _hasKeyword(fields.keyword, Keyword.CONST) ||
      _hasKeyword(fields.keyword, Keyword.FINAL);
}

void _transformGetter(SourceFile file,MethodDeclaration member,TextEditTransaction code, BuildLogger logger) {
  if (_hasObservable(member)) {
    code.edit(member.metadata.first.offset,member.metadata.first.offset,"@reflectable ");

  }
}

void _transformFields(SourceFile file, FieldDeclaration member,
    TextEditTransaction code, BuildLogger logger) {
  final fields = member.fields;

  String metadata = '';
  if (fields.variables.length > 0) {
    code.edit(member.metadata.first.offset,member.metadata.first.offset,"@reflectable ");

  }

}

Token _findFieldSeperator(Token token) {
  while (token != null) {
    if (token.type == TokenType.COMMA || token.type == TokenType.SEMICOLON) {
      break;
    }
    token = token.next;
  }
  return token;
}

// TODO(sigmund): remove hard coded Polymer support (@published). The proper way
// to do this would be to switch to use the analyzer to resolve whether
// annotations are subtypes of ObservableProperty.
final observableMatcher =
    new RegExp("@(observable|Observable)");
