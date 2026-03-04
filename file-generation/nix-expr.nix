{
  lib,
  ...
}:

let
  inherit (builtins)
    all
    any
    attrNames
    concatStringsSep
    elemAt
    foldl'
    genericClosure
    genList
    head
    isAttrs
    isFloat
    isInt
    isList
    isPath
    isString
    length
    mapAttrs
    match
    replaceStrings
    sort
    split
    stringLength
    substring
    typeOf
    zipAttrsWith
  ;
  inherit (lib)
    attrsToList
    boolToString
    concatMapStrings
    concatMapStringsSep
    const
    filterAttrs
    groupBy'
    hasInfix
    hasPrefix
    hasSuffix
    lists
    mapAttrsToList
    mkOption
    optional
    optionalString
    path
    pipe
    removePrefix
    removeSuffix
    types
    unique
  ;
  inherit (path)
    subpath
  ;
  inherit (lib.strings)
    escapeNixIdentifier
    escapeNixString
  ;
  inherit (lib.attrsets)
    unionOfDisjoint
  ;

  getSingleton = list: if length list == 1 then head list else throw "List is not a singleton";
  switchAttrTag = default: branches: taggedattrs: ({name, value}: (branches.${name} or (default name)) value) (getSingleton (attrsToList taggedattrs));
  tagValue = tag: x: { ${tag} = x; };
  tagResult = tag: f: x: tagValue tag (f x);
  switchType = default: branches: value: (branches.${typeOf value} or (default (typeOf value))) value;
  indentString = ind: str: if str == "" then "" else concatMapStrings (x: if isString x then x else elemAt x 0 + ind) (split "((^|\n)+)" (removeSuffix "\n" str)) + optionalString (hasSuffix "\n" str) "\n";
  wrapNonEmpty = l: str: r: if str == "" then "" else l + str + r;

  prec = {
    inner  =  0; # tightest-binding
    sel    =  1; # a.b
    app    =  2; # a b
    neg    =  3; # -a
    has    =  4; # a ? b
    concat =  5; # a ++ b
    mul    =  6; # a * b
    plus   =  7; # a + b
    lnot   =  8; # ! a
    upd    =  9; # a // b
    comp   = 10; # a < b
    eq     = 11; # a == b
    land   = 12; # a && b
    lor    = 13; # a || b
    impl   = 14; # a -> b
    pipe   = 15; # a |> b
    outer  = 16; # loosest-binding
  };
  maybeParen = { outerPrec ? prec.outer, chain ? true, ... }: innerPrec: expr:
    if outerPrec < innerPrec || outerPrec == innerPrec && ! chain then
      if isList (match ".*(\n.*)+" expr) then
        "(\n" + indentString "  " expr + "\n)"
      else
        "(" + expr + ")"
    else
      expr;
  concatStringsMapOthers = f: xs: let
    res = foldl' (a: x:
      if      a ? part && isString x then
        a // { part = a.part + x; }
      else if             isString x then
        a // { part = x; }
      else if a ? part && a.part != "" then
        { list = a.list ++ [ a.part (f x) ]; }
      else
        { list = a.list ++ [ (f x) ]; }
    ) { list = []; } xs;
  in
    res.list ++ optional (res ? part) res.part;
  concatMapStringsWithLookahead = f: xs: let len = length xs; in concatStringsSep "" (genList (i: f (elemAt xs i) (if i+1 < len then elemAt xs (i+1) else null)) len);

  impl = {
    literal.normalize = ctx: data: normalizeNixExpr ctx (switchType tagValue {
      null = tagResult "var"  (const "null");
      bool = tagResult "var"   boolToString;
      list = tagResult "list" (map (tagValue "literal"));
      set  = tagResult "set"  (tagResult "defs" (mapAttrs (n: tagValue "literal")));
      lambda = throw "Cannot serialize a lambda as a literal";
    } data);
    save.normalize = ctx: { exprs ? {}, eqs ? {}, body}: normalizeNixExpr (ctx // { exprs = (ctx.exprs or {}) // exprs; eqs = (ctx.eqs or {}) // eqs; }) body;
    saved.normalize = ctx: name: normalizeNixExpr ctx ((ctx.exprs or {}).${name} or (throw "no saved expression by name ${name}"));

    format.normalize = ctx: { expr, ... }@arg: { format = arg // { expr = normalizeNixExpr ctx expr; }; };
    format.render = ctx: { before ? "", after ? "", expr }:
      if
        all (s: isList (match "([ \n\t]+|#[^\n]*\n|/\\*([^*]|\\*+[^*/])*\\*+/)*" s)) [ before after ]
      then
        before + renderNixExpr ctx expr + after
      else
        throw "the 'before' and 'after' elements of a 'format' node can only include whitespace and comments";

    var.render = ctx: name: if isList (match "[A-Za-z_][A-Za-z0-9_'-]+" name) && isNull (match "assert|else|if|in|inherit|let|or|rec|then|with" name) then name else throw "bad variable name: ${name}";

    int.render = ctx: i: if isInt i then toString i else throw "contents of 'int' node not an integer";

    float.render = ctx: f: if isFloat f then toString f else throw "contents of 'float' node not a float";

    # FIXME move path-type conversion to normalization phase and allow string-based specification and antiquotes
    path.render = ctx: p: if isPath p then mkNixPath ctx p else throw "contents of 'path' node not a path";

    string.normalize = ctx: repr: normalizeNixExpr ctx {
      string =
        if hasInfix "\n" repr then
          tagValue "dsstring" repr
        else
          tagValue "sdstring" repr;
      set = tagValue "sdstring" repr;
      list =
        if any (x: isString x && hasInfix "\n" x) repr then
          tagValue "dsstring" repr
        else
          tagValue "sdstring" repr;
    }.${typeOf repr} or (throw "unknown string representation type: ${typeOf repr}");

    sdstring.normalize = ctx: repr: {
      string = tagValue "sdstring" [ repr ];
      set = tagValue "sdstring" [ (normalizeNixExpr ctx repr) ];
      list = tagValue "sdstring" (concatStringsMapOthers (normalizeNixExpr ctx) repr);
    }.${typeOf repr} or (throw "unknown sdstring representation type: ${typeOf repr}");
    sdstring.render = ctx: repr: "\"" + renderUnwrappedNixString "sd" ctx repr + "\"";

    dsstring.normalize = ctx: repr: {
      string = tagValue "dsstring" [ repr ];
      set = tagValue "dsstring" [ (normalizeNixExpr ctx repr) ];
      list = tagValue "dsstring" (concatStringsMapOthers (normalizeNixExpr ctx) repr);
    }.${typeOf repr} or (throw "unknown dsstring representation type: ${typeOf repr}");
    dsstring.render = ctx: repr: let
      rendered = renderUnwrappedNixString "ds" ctx repr;
      willLoseTrailingSpaces = isList (match ".*\n +" rendered);
      willEatIndents = isNull (match ".*(^|\n)[^ \n].*" (concatMapStrings (x: if isString x then x else "a") repr));
      fixed =
        if willLoseTrailingSpaces then # We escape the first space on the last line so it also fixes any indent-eating
          concatMapStrings (x: if isString x then x else elemAt x 0 + "''\\ " + elemAt x 1) (split "(^|\n) ( *)$" rendered)
        else if willEatIndents then
          concatMapStrings (x: if isString x then x else elemAt x 0 + "''\\ " + elemAt x 1) (split "(^|\n) (.*)$" rendered)
        else
          rendered;
    in
      if any (x: isString x && hasInfix "\n" x) repr then
        "''\n" + indentString "  " fixed + "''"
      else
        "''" + fixed + "''";

    list.normalize = ctx: tagResult "list" (map (normalizeNixExpr ctx));
    list.render    = ctx: list: "[" + wrapNonEmpty "\n" (indentString "  " (concatStringsSep "\n" (map (renderNixExpr (ctx // { outerPrec = prec.app; chain = false; })) list))) "\n" + "]";

    # FIXME add support for antiquotes in LHS of definitions
    set.normalize = ctx: tagResult "set" (normalizeNixEqs ctx);
    set.render    = ctx: eqsArgs: "{" + wrapNonEmpty "\n" (indentString "  " (renderNixEqs ctx eqsArgs)) "\n" + "}";

    recset.normalize = ctx: tagResult "recset" (normalizeNixEqs ctx);
    recset.render    = ctx: eqsArgs: "rec {" + wrapNonEmpty "\n" (indentString "  " (renderNixEqs ctx eqsArgs)) "\n" + "}";

    # FIXME add support for 'or'
    # FIXME add support for antiquotes in 'attr'
    sel.normalize = ctx: { from, attr }: pipe (normalizeNixExpr ctx from) (map (n: f: { sel.from = f; sel.attr = n; }) (if isList attr then attr else [ attr ]));
    sel.render = ctx: { from, attr }: maybeParen ctx prec.sel ( # FIXME only allow single attr in render stage?
      renderNixExpr (ctx // { outerPrec = prec.sel; chain = true; }) from + concatMapStrings (attr: "." + escapeNixIdentifier attr) (if isList attr then attr else [ attr ])
    );

    app.normalize = ctx: { func, arg, args ? {} }:
      if isList arg then
        assert sort (x: y: x < y) (unique arg) == attrNames args;
        pipe (normalizeNixExpr ctx func) (map (n: f: { app.func = f; app.arg = normalizeNixExpr ctx args.${n}; }) arg)
      else
        assert args == {};
        {
          app.func = normalizeNixExpr ctx func;
          app.arg = normalizeNixExpr ctx arg;
        };
    app.render = ctx: { func, arg }: maybeParen ctx prec.app (
      renderNixExpr (ctx // { outerPrec = prec.app; chain = true; }) func + " " + renderNixExpr (ctx // { outerPrec = prec.app; chain = false; }) arg
    );

    branch.normalize = ctx: tagResult "branch" (mapAttrs (n: normalizeNixExpr ctx));
    branch.render    = ctx: { cond, truecase, falsecase }: maybeParen ctx prec.outer (
      removeSuffix "\n" ''
        if
        ${indentString "  " (renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) cond)}
        then
        ${indentString "  " (renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) truecase)}
        else
        ${indentString "  " (renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) falsecase)}
      ''
    );

    letin.normalize = ctx: tagResult "letin" ({ defs ? {}, inh ? {}, saved ? [], body }: normalizeNixEqs ctx { inherit defs inh saved; } // { body = normalizeNixExpr ctx body; });
    letin.render    = ctx: { defs ? {}, inh ? {}, body }: maybeParen ctx prec.outer (
      removeSuffix "\n" ''
        let
        ${indentString "  " (renderNixEqs ctx { inherit defs inh; })}
        in
        ${indentString "  " (renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) body)}
      ''
    );

    # FIXME add support for attrset arg deconstruction
    lambda.normalize = ctx: tagResult "lambda" ({ var, body }: { inherit var; body = normalizeNixExpr ctx body; });
    lambda.render    = ctx: { var, body }: maybeParen ctx prec.outer (
      var + ": " + renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) body
    );

    withexp.normalize = ctx: tagResult "withexp" ({ from, body }@args: mapAttrs (n: normalizeNixExpr ctx) args);
    withexp.render    = ctx: { from, body }: maybeParen ctx prec.outer (
      "with " + renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) from + "; " + renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) body
    );

    assertion.normalize = ctx: tagResult "assertion" ({ cond, body }@args: mapAttrs (n: normalizeNixExpr ctx) args);
    assertion.render    = ctx: { cond, body }: maybeParen ctx prec.outer (
      "assert " + renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) cond + "; " + renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) body
    );
  };

  normalizeNixExpr = ctx: switchAttrTag tagValue (mapAttrs (n: v: v.normalize ctx) (filterAttrs (n: v: v ? normalize) impl));
  renderNixExpr = ctx: switchAttrTag (name: throw "renderNixExpr: unknown tag ${name}") (mapAttrs (n: v: v.render ctx) (filterAttrs (n: v: v ? render) impl));

  normalizeNixEqs = { eqs ? {}, ... }@ctx: { defs ? {}, inh ? {}, saved ? [] }: zipAttrsWith (n: foldl' unionOfDisjoint {}) (
    map ({defs, inh, ...}: {
      defs = mapAttrs (n: normalizeNixExpr ctx) defs;
      inh = mapAttrs (n: x: if isAttrs x then normalizeNixExpr ctx x else x) inh;
    }) (genericClosure {
      startSet = [ { key = "body"; inherit defs inh saved; } ];
      operator = a: map (name: { defs = {}; inh = {}; saved = []; } // eqs.${name} or (throw "no saved eqs: ${name}") // { key = "saved:" + name; }) (a.saved or []);
    })
  );
  renderNixEqs = ctx: { defs ? {}, inh ? {} }: let
    mkNixEq = n: v:
      if v ? set && length (attrNames v.set.inh or {}) == 0 && length (attrNames v.set.defs or {}) == 1 then
        ({name, value}: escapeNixIdentifier n + "." + mkNixEq name value) (getSingleton (attrsToList v.set.defs))
      else
        escapeNixIdentifier n + " = " + renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) v + ";";
    deflines = mapAttrsToList mkNixEq defs;
    collatedInh = groupBy' (ns: {name, ...}: ns ++ [ name ]) [] ({ value, ... }: if isAttrs value then renderNixExpr (ctx // { outerPrec = prec.outer; chain = true; }) value else "") (attrsToList inh);
    inhlines = mapAttrsToList (n: v: "inherit " + wrapNonEmpty "(" n ") " + concatMapStringsSep " " escapeNixIdentifier v + ";") collatedInh;
  in concatStringsSep "\n" (inhlines ++ deflines);

  renderUnwrappedNixString = type: ctx: concatMapStringsWithLookahead (cur: next: let
    sequentialStrings = typeOf cur == "string" && typeOf next == "string";
    antiquoteFollows = typeOf next == "set";
    ending = elemAt (match ''.*([^'$]|^)('?(\$')*\$\$|\$?('\$)*''')*('?(\$')*\$?)'' cur) 4;
    endingLength = stringLength ending;
    discriminator = substring (if endingLength >= 2 then endingLength - 2 else 0) endingLength ending;
    escapeFinalDollar = antiquoteFollows && discriminator == "$";
    escapeFinalTickDollar = antiquoteFollows && discriminator == "'$";
    mostlyEscaped = {
      sd = replaceStrings
        [       "$$"                "\${"   "\\"   "\""  "\n"                 "\r"                 "\t" ]
        [       "$$"              "\\\${" "\\\\" "\\\"" "\\n"                "\\r"                "\\t" ]
        cur;
      ds = replaceStrings
        [  "''" "$$"       "'\${"   "\${"                            "'\r"    "\r"        "'\t"    "\t" ]
        [ "'''" "$$" "''\\'''\${" "''\${"                     "''\\'''\\r" "''\\r" "''\\'''\\t" "''\\t" ]
        cur;
    }.${type};
  in
    if sequentialStrings then
      throw "non-normalized string representation."
    else if typeOf cur != "string" then
      "\${" + renderNixExpr ctx cur + "}"
    else if escapeFinalDollar then
      removeSuffix  "$" mostlyEscaped + { sd =  "\\$"; ds =      "''$"; }.${type}
    else if escapeFinalTickDollar then
      removeSuffix "'$" mostlyEscaped + { sd = "'\\$"; ds = "''\\'''$"; }.${type}
    else
      mostlyEscaped
  );


  mkNixExpr = ctx: expr: renderNixExpr ctx (normalizeNixExpr ctx expr);
  mkNixEqs  = ctx:  eqs: renderNixEqs  ctx (normalizeNixEqs  ctx  eqs);

  mkNixPath = { toplevel, targetfile, ... }: p: let
    targetcomps = subpath.components (path.removePrefix toplevel (dirOf targetfile));
    pathcomps = subpath.components (path.removePrefix toplevel p);
    common = lists.commonPrefix targetcomps pathcomps;
    pathcompregex = "[-A-Za-z0-9._+]+";
  in
    pipe (map (const "..") (lists.removePrefix common targetcomps) ++ lists.removePrefix common pathcomps) [
      (cs: if length cs == 0 then [ "." ] else cs)
      (cs: if isNull (match pathcompregex (head cs)) then [ "." ] ++ cs else cs)
      (cs: if length cs <= 1 then [ "." ] ++ cs else cs)
      (map (c: if isList (match pathcompregex c) then c else "\${" + escapeNixString c + "}"))
      (concatStringsSep "/")
    ];
in

{
  config = {
    my.lib = {
      inherit
        mkNixExpr
        mkNixEqs
      ;
    };
  };
}
