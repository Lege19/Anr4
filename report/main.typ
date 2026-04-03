#import "template.typ": AUTHOUR, DEV_MODE, TITLE, make_outline, show_warnings, styles, titlepage, warning_count

#set document(title: TITLE, author: AUTHOUR)

#show: it => if DEV_MODE {
  // Display warnings at the very top of document
  show_warnings
  // Display warning count at the bottom of every page
  set page(background: warning_count)
  it
} else { it }

#titlepage

#show: styles

#make_outline

= Analysis
#counter(page).update(1)
#include "analysis/main.typ"
= Design
#include "design/main.typ"
= Implementation <implementation-section>
#include "implementation.typ"

= Testing
#include "testing/main.typ"
= Evaluation
#include "evaluation/main.typ"

#bibliography("bibliography.bib", style: "ieee")

#set page(header: h(1fr) + link(<implementation-section>)[Implementation])
#heading(supplement: [Appendix A], numbering: none)[Appendix A: Code Listing]<full-code-listing>
#counter(heading).step()
#include "code_listing.typ"
