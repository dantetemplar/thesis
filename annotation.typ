#import "template.typ": template, numbering

#set page(margin: 0pt)
#image("annotation-title.pdf", width: 100%, height: 100%)
#pagebreak()

#show: template

#set text(lang: "ru")

#set page(
  margin: (
    left: 2.5cm,
    top: 2cm,
    right: 2cm,
    bottom: 2cm,
  ),
  header: none,
  footer: none,
)

#set par(first-line-indent: 1.25cm)

#show heading.where(level: 1): it => {
  pagebreak(weak: true)

  set par(first-line-indent: 0cm)
  set text(font: "Times New Roman", size: 1.25em, weight: "bold")

  block(breakable: false, spacing: 0.65em)[
    #if it.numbering != none {
      counter(heading).display() + ". "
    }
    #it.body
  ]
}

#show heading.where(level: 2): it => {
  set par(first-line-indent: 0cm)
  set text(font: "Times New Roman", size: 1.1em, weight: "bold")

  block(breakable: false, spacing: 0.45em)[#it.body]
}

#show ref: it => {
  let eq = math.equation
  let el = it.element
  if el != none and el.func() == eq {
    numbering(
      el.numbering,
      ..counter(eq).at(el.location())
    )
  } else {
    it
  }
}

#set ref(supplement: none)

#counter(page).update(2)

#show: numbering

#set page(
  footer: context {
    align(center)[#counter(page).display("1")]
  },
)

#include "sections/annotation/contents.typ"
#include "sections/annotation/foreword.typ"
#include "sections/annotation/main-part.typ"
#include "sections/annotation/conclusion.typ"
#include "sections/annotation/references.typ"
