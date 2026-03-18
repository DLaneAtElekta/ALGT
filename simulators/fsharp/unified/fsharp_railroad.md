# F# Language - Railroad Diagrams

Generated from `fsharp_parser.pl` DCG rules.

## app_expr

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n3["primary"]
    n5["app_expr_rest"]
    n0 --> n3 --> n2
    n2 --> n4
    n4 --> n5 --> n1
```

## app_expr_rest

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n4["primary"]
    n8["app_expr_rest"]
    n0 --> n1
    n0 --> n2
    n2 --> n4 --> n3
    n3 --> n5
    n5 --> n6
    n6 --> n7
    n7 --> n8 --> n1
```

## arith_expr

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n3["term"]
    n4["arith_expr_rest"]
    n0 --> n3 --> n2
    n2 --> n4 --> n1
```

## arith_expr_rest

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n11(["-"])
    n14["term"]
    n17["arith_expr_rest"]
    n3(["+"])
    n6["term"]
    n9["arith_expr_rest"]
    n0 --> n1
    n0 --> n11 --> n10
    n0 --> n3 --> n2
    n10 --> n12
    n12 --> n14 --> n13
    n13 --> n15
    n15 --> n16
    n16 --> n17 --> n1
    n2 --> n4
    n4 --> n6 --> n5
    n5 --> n7
    n7 --> n8
    n8 --> n9 --> n1
```

## binding

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n12(["="])
    n15["expr"]
    n3[/"let"/]
    n6["ident"]
    n9["ident"]
    n0 --> n3 --> n2
    n10 --> n12 --> n11
    n11 --> n13
    n13 --> n15 --> n14
    n14 --> n1
    n2 --> n4
    n4 --> n6 --> n5
    n5 --> n7
    n7 --> n8
    n7 --> n9 --> n8
    n8 --> n10
    n9 -.-> n7
```

## expr

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n2["arith_expr"]
    n0 --> n2 --> n1
```

## factor

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n2["app_expr"]
    n0 --> n2 --> n1
```

## primary

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n10([")"])
    n2["number"]
    n3["ident"]
    n5(["("])
    n8["expr"]
    n0 --> n2 --> n1
    n0 --> n3 --> n1
    n0 --> n5 --> n4
    n4 --> n6
    n6 --> n8 --> n7
    n7 --> n9
    n9 --> n10 --> n1
```

## program

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n4["binding"]
    n0 --> n2
    n2 --> n3
    n2 --> n4 --> n3
    n3 --> n1
    n4 -.-> n2
```

## term

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n3["factor"]
    n4["term_rest"]
    n0 --> n3 --> n2
    n2 --> n4 --> n1
```

## term_rest

```mermaid
flowchart LR
    n0(((" ")))
    n1(((" ")))
    n11(["/"])
    n14["factor"]
    n17["term_rest"]
    n3(["*"])
    n6["factor"]
    n9["term_rest"]
    n0 --> n1
    n0 --> n11 --> n10
    n0 --> n3 --> n2
    n10 --> n12
    n12 --> n14 --> n13
    n13 --> n15
    n15 --> n16
    n16 --> n17 --> n1
    n2 --> n4
    n4 --> n6 --> n5
    n5 --> n7
    n7 --> n8
    n8 --> n9 --> n1
```

