# Associate Editor comments to the Author

Thank you for submitting your article to Methods in Ecology and Evolution, and
also to the reviewers for their hard work reviewing this manuscript.

I am grateful for the effort that you have put into revising this manuscript
along the lines that were suggested, and I think it has greatly improved the
quality of the manuscript. In addition to the comments of the reviewers, I
highlight a few things that occurred to me as I read the article through this
time. Please address these clearly in your revision; it is my hope that a few
essentially cosmetic changes to the text to address the below will allow for
this article to move to production without requiring more review than me
glancing through the changes you have made. Please, in particular, pay attention
to my comments on bullet point 4 below - there is a slight framing problem with
the opening of your article.

"degree of unbiasing" (Abstract) - Unclear what this means

"ROC AUC" (Abstract) - Spell out acronyms that are defined in the abstract (I
appreciate that these are not unique to this paper, but PR-AUC is perhaps less
commonly used)

"the network" (line 13) --> "the true network" instead, perhaps?

"k was a better test of model performance" (line 18) leads the reader, I think,
to wonder "what is 'k'?" This issue is quite important because you define, in
the "Primer on binary classification evaluation" below, k and many others of
these terms, but assume the definitions are already known here (earlier in the
article) which will make the article unnecessarily intimidating for how clearly
and helpfully you define terms later. If you can't think of a structural way to
address this more clearly (and I'm not sure I can besides merging this with the
primer that follows, which feels like a bad idea), I suggest you 'say the quiet
part out loud': (1) tell the reader that you will define all the terms later
(and make sure you use consistent names for them throughout; see below for more
details on that too) and (2) highlight that it's not the metrics themselves that
are of interest at this point more than there is no consensus as to which metric
should be used and what approach employed to maximise/minimise them.

"spatial thinning (a process that has no analogue in networks)" (line 23). With
all the listing of terms (and here in particular), it isn't clear what you're
trying to demonstrate. Tell us the context - why is this a relevant thing to be
bringing up (i.e., what problem does it solve, and why is it a useful
comparison), particularly given you then point out it has no analogue in network
models. If there's no analogue, then why is this a relevant comparison to be
making?

"Cohen's k" (line 34) - 'k' re-appears here, but named differently. See also
below - be consistent with your definitions.

"Binary classifiers, which is to say, machine learning algorithms whose answer
is a categorical value" (line 68). Binary is not the same thing as categorical.
I appreciate that many ML algorithms use binary prediction to handle more than
one variable via sequentially applying methods, not all do (one could argue
multinomial regression is categorical) and so this could be revised for clarity.

"Informedness (Youden, 1950) (also known as bookmaker informedness or the True
Skill Statistic)" (line 89) use the same name for this throughout - put the main
name you use in the body of the text, not in the parentheses, I think.

Line 100: Don't define the ROC and the PR curves after you've discussed them -
define them and then discuss them.

Line 117: Is p really a network? It seems as though it's a scalar here because
it's multiplied by the dimension of the network (S^2) to get the number of
connections. Below the same term is also used to introduce the probability of
interactions so I don't think it can be, but perhaps I am missing something.
Please also check the rest of the manuscript for issues such as this; given this
definitional issue here and also a few re-namings of terms I found above I think
the manuscript would benefit from one more read through.

"]0,0.5]" (line 259) typo

".e.g." (line 367) typo

"fig. 1 and network connectance fig.2" --> "(fig. 1) and network connectance
(fig.2)" typo?

"a lot of networks admit a stochastic block model as a good approximation"
(lines 423-424). "Admit" feels like an odd word to use here; perhaps you mean
"fit"?

"constrains" (line 425) --> "constraints"

"use the more usual 70/30 split" (line 430). You do make reference to
training/validation fractions (and this fraction in particular) earlier in the
article, but I think you could be a little clearer what you mean here. This is
also a very long sentence; see if you can cut it in half at the semi-colon for
greater clarity.

# Reviewer 3

I think the author has address successfully the comments made by the associate
editor and the reviewers, including myself. As a result, the revised manuscript
has improved in several important ways. Most of my original comments had to do
with the clarity in the presentation of ideas and the description of methods,
and the revised manuscript has improved substantially in these respects. The new
introduction now does a great job at presenting the key ideas to understand the
problem addressed in the manuscript, the description of the methods and the
results are now easier to follow, and the guidelines are more accessible for the
non-specialist reader.

# Reviewer 2

I reviewed a previous version of this manuscript and appreciate how the author
has placed the revised version more clearly in an ecological context which I
think makes the text more accessible. The author has also done a good job in
addressing my previous comments, so that my remaining comments and suggestions
are mostly minor and on the editorial side of things.

L1: Perhaps: “Species interactions form ecological networks, the backbone of key
ecological and evolutionary processes; […]”

L6-9: “these models”, “the models” -> perhaps be more specific e.g. “models for
network predictions”

L15: I would consider SDMs a technique implemented within the fields of
macroecology and biogeography. Perhaps change to “[…] field in biology: species
distribution modelling (SDMs), and genomics […]”

L17: Consider adding a sentence to link the two sentences and improve the flow
of the text in this section.

L18: define K (kappa) when first mentioned.

L23: could an analogue to spatial sampling bias in species occurrence data, be
taxonomic bias in ecological networks? So that e.g. locally abundant plants are
likely to have more interactions recorded on them then locally rare plants
despite that local abundance may not reflect regional abundance.

L34: “relative nature of k” please define kappa first, so that this statement is
understandable by a wide readership.

L53: With “indicators” I suppose you are referring to the four metrics you
apply/test? If so then consider rewording to use a consistent terminology
throughout.

L66: add sentence linking this section to the next.

L70: should this read: “true/false OR positive/negative”?

L84: add abbreviations for the ROC and PR

L87: the k measure is earlier called ‘cohens k’, please check for consistency.
Also perhaps add reference to Cohen 1960.

L107-109: “The ROC curve is defined […]” perhaps move this sentence up to L100
(following “[…] threshold maximizing some value on the ROC or the PR curve.”)?

L213: should this read: “[…] composed of a random sample consisting of 50% of
the 10^4 possible entries in the network”?

L215: The rebalancing needs a bit more elaboration. If you have 5K species-pairs
(n) in your ‘full’ training-sample where the connectance equals that of the
testing data, and determines the number of presences of interactions. Then if
you want to set the proportion of interactions (v) at e.g. 10% then I would
think that you either have to strip away presence data, or absence data from
your training-sample. Would the equation defining your sample size would
therefore not have to include a factor to correct for the initial proportion of
presences? i.e. be v*c*n instead of just v*n and could the varying sample sizes
in your training data affect model performances across your balancing gradient?

L227: throughout the manuscript you focus on classifiers, but here you use e.g.
regression trees instead of classification trees. For the reader this comes as a
bit of a surprise and could do with a short reasoning.

L239: Please motivate the use of the accuracy measure when training the models
given the caveats of this index (highlighted on L144).

L247: Perhaps motivate the choice of the informedness index here.

L352: “[…] and so the network itself contained less information than the network
[…]” something is a bit odd with this sentence, consider revising.

L356-358: Consider adding a short sentence describing how one would assess e.g.
the optimal training set balance.

L367: should “.e.g.” be “e.g.”?

L373: “esemble” -> “ensemble”