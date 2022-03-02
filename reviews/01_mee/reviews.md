# Associate Editor Comments to Author:

Thank you for submitting your manuscript to Methods in Ecology and Evolution,
and also to the reviewers for their hard work. I found this manuscript very
interesting, but like the reviewers I found it difficult to follow in places.
Below I have a number of recommendations, many of which build on the reviewers'
suggestions. I urge the author to carefully read through all the reviewers'
suggestions, in particular the major comments raised by R2 and R3, every one of
which I feel are very important to be addressed.

> Thank you for the opportunity to submit a revised manuscript. Yours and the
reviewers' comments helped immensely in making the text more accessible, and
I hope that the revised version will meet the standards of Methods in Ecology
& Evolution. I have provided a point-by-point response to all comments, but
I would like to summarize the most significant changes:

> First, the introduction was almost entirely re-written, to ensure that the
context (*i.e.* ecological networks) comes first; the section that was
initially the introduction is now a short primer on the evaluation of binary
classifiers, which should provide readers with the necessary background to
assess the results.

> Second, the models in the manuscript have changed; the point of including
ridge regression, as in the original submission, was to show that a model can
appear to perform well but miss the actual data structure. Some comments by the
reviewers made me reconsider this, and I think it would have been setting
a misleading example to put a poor model in an ensemble. I have replaced ridge
regression by a k-NN trained on *traits*, which performs well. Note that this
still allows to have a discussion on the fact that good validation metrics and
good network predictions are not necessarily one and the same.

> Finally, I have changed the training strategy a little, in a way that
addresses multiple comments at once. The nature and extent of changes are
outlined in the responses to the respective comments, but the main consequence
is that the last section of the manuscript is now a little bit more
"normative", as adopting the proper training strategy reveals generalities that
I had missed in the previous version. For the comments that led to this
decision, I am particularly grateful.

This article is unusual, in that it is more of an essay than a standard
intro/methods/results/discussion paper. There is nothing wrong with that (in
fact I applaud it for that), but more needs to be done to make it easy for the
reader to understand everything. There are many places in the article where it
is unclear exactly what the author has done, what the back-up for statements
the author has made is, and (perhaps most importantly) what the author's
motivation is in choosing a particular approach. I encourage the author to
write for a broad audience - motivate the biology for those who are already
familiar with the ML, and bring the biologist along for the ride with the ML
itself. I can envisage this being a classic graduate-level ML class reading
paper, but only if the reader is brought along for the ride so they can follow
the argument. This article could have a wide readership and broad impact, but
to do that it needs to be clearer. The article feels like a labour of love, and
I think if the labour is made a little clearer others will love it and engage
with it rather than being unable to understand it fully.

> This is a fair point -- I have added a number of references throughout, and
now start with a discussion that is grounded in ecology (networks, then the
parallels with SDMs, then switching into machine learning). Following the
revisions to the code, the text has been updated in ways that I think will
clarify what exactly has been done.

More broadly, I encourage the author to introduce a broader, more engaging
opening that bring in the motivation for the work (see R3's comments on this in
particular), but also to motivate the general results throughout. The author is
not taking a standard methods/results structure here, I sense, because they
want to build an argument throughout an essay. That's fine, but they need to
make the argument clearer. The article ends and I don't know what the general
take-homes are: the author almost seems to argue that every particular setup
will be different and so we can't take any generalities away from this piece.
I don't believe that for a second: the author has chosen these particular
formulations and this particular approach to make an argument for what they
think are general take-homes and guiding principles. Tell us what those
take-homes are, both during the article ("OK, so we now have learned XXX, now
we must know YYY") and then conclude by reviewing the generalities and from
there some future directions. The opening pages (particularly lines 120-132)
which contain more maths are actually clearer in terms of general take-homes --
that level of clarity for the later sections would help I think.

> As mentioned in the first paragraph of the response, the changes to the
manuscript led to a series of stronger recommendations in the last section.
I still stand by the point that we should not adopt a cookbook approach to
network prediction, but I have nevertheless identified guiding principles and
possible caveats.

More specific comments and examples of places where clarity could be improved:

Please release the code underlying this work; doing so might also help the
author in terms of how much methodological information they have to include in
the main text. If the author is very concerned about the flow of the text
(although, I emphasise, at present there is a lack of clarity so more
methodological detail is needed in the main text) perhaps supplementary
materials could be used to help keep things streamlined in the main text.

> This was an oversight on my part, and I do apologize for this. The code was
linked to the preprint version, and I did not checked that it was also linked
in the main text. The code is accessible on GitHub, as well as on OSF.io (a DOI
is given in the main text). Following the changes requested by the reviewers,
I have done a lot of refactoring, so the code should be easier to read.

"which is within the range of usually observed connectance values for empirical
food webs" (line 135). "there is an almost 1:1 relationship between 𝜉 and
connectance" (lines 173-174). Where is the evidence for these statements? In
places such as these the author makes statements that I sense they know to be
true because of their depth of understanding of the field; please add citations
even if these statements seem trivial to you.

> These have been clarified in the text. The relationship with $\xi$ was simply
revealed by looking at the inputs and outputs of the network generating
function.

"this works without loss of generality on unipartite networks" (lines 168-169).
In places the author makes claims, such as this one, where it is not clear
where there is literature support. If this is an obvious mathematical
derivation or fact, please spell it out.

> I have rephrased this sentence at TODO.

"tp is the number of interactions predicted as positive (line 18). This is
a good example of where terminology is not helping the reader - the author
misses an opportunity here to explain that this term is called 'tp' because it
is related to 'true positives'. The author hints at it just before the matrix
definition but doesn't spell it out - there is so much going on for a reader
who is new to the field that the author must be crystal clear I think.

> I have rephrased this section (TODO), and I hope that it will clarify what
each of the entries in the matrix represent.

"This model is easy to learn" (line 176). I recognise that the author means
"easy for the ML model to predict", but I would use a different phrase as it
will come across to the non-specialist at first-glance as "there's nothing hard
about the maths in this paper" which will be a bit intimidating because the
maths is quite tricky here!

> This is a good point - I have remove this sentence, to focus on the fact that
the relationships in the data are simple for a good model to pick-up on.

# Reviewer 1

This manuscript examines various performance metrics of machine learning
algorithms applied to species interactions networks. It is clearly written and
succinct. I do not work on species interaction networks (and I highly recommend
that another reviewer with this expertise also evaluates the manuscript) but
I was able to understand what the author set out to do. The discussion of how
the various performance metrics measure different things and what the pros and
cons are how they relate species interaction networks seems like an important
contribution to the field but I have insufficient background knowledge to
comment on the novelty. Many of the findings are relevant to tradeoffs and
performance metrics used in machine learning in general. If I were to make one
general suggestion that could perhaps improve the study is to use a wider range
of simulation conditions.

> I thank the reviewer for their kind words about the manuscript. I have added
a broader range of simulations (and increased the number of simulated networks
to 612500, so that each point is the average of 500 independent replicates.
This gives much clearer results, while also avoiding issues with binning
connectances for some of the later sections. Please also note that the models
have been changed, to better reflect what would probably be the immedidate
picks for ecological network predictions.

The author notes that he found the ensemble method better than component models
but this is not what other model comparisons found. The author says that the
findings described here should not be generalized to say that ensemble models
are always better but the relationship between ensemble performance and the
various metrics explored is not clear to me. If it is possible that under more
general simulation conditions the ensemble would not be the best-performing, is
it also possible that some of the observations about the metrics would not hold
either? Something to think about.

> I too am wondering about why the ensemble is out-performing the other models.
If I had to take a guess, I would simply accept it as a "happy accident" due to
the type of simulated data, and as I mention in the paper, I do not think this
is a general feature; I have added  the discussion of the ensemble at the
beginning of the "guidelines" section, and emphasized that there is no general
conclusion to draw here.

I include the manuscript text with additional minor comments and typos
corrected where I caught them.

> These have been fixed, thank you!

# Reviewer 2

In “Guidelines for the validation of machine learning of predictions of species
interactions” Prof. Poisot addresses an important challenge in network-ecology:
how to model and assess predictions on species-interaction data that is
typically dominated by absences. Using mathematical arguments, and with
references to other fields, the author convincingly shows how commonly used
indicators of prediction accuracy (e.g. ROC-AUC) will be biased in cases where
absences of interactions are dominant. In the second part of the paper the
author uses simulations to show how different types of machine learning methods
perform by assessing their classification accuracy with different metrics and
finally by assessing the ability of different models to predict the structure
of entire network. In the final section the author lays out a series of
guidelines for modelling species interactions: MCC and PR-AUC should be the
preferred model assessment criteria, and training-data should be biased to
increase the amount of presences available for training models. Overall I think
the paper has the potential to be an important contribution to network
modelling and prediction. I think some parts of the manuscript need a bit more
elaboration and have made some comments and suggested edits below that I hope
you will find useful.

## General comments

(1) The use of machine learning is gaining momentum in the study of species
interactions and the article is likely to be of interest to quite a wide
audience working on different systems.

(a) outline different types of interactions and how resulting interaction
networks might differ in relation to the simulations in this study,

> This is a good point -- I have added a section in the guidelines regarding
different types of interactions (TODO).

(b) outline how the suggested guidelines would work when predicting across
networks

> TODO

(c) outline how the biasing of testing data differs from other methods of
data-thinning applied in e.g. SDMs.

> This is a good point -- I have added a discussion of this point in the
introduction, specifically at TODO.

(2) Consider adding a motivation for the choice of the different indices and
machine learning methods that are assessed and compared in the paper e.g. by
referring to their use in recent studies of species-interactions.

> TODO clarify

(3) I was surprised to see that RF models performed so poorly compared to BRT,
because this contrasts what other studies have found. I think it would be
useful to elaborate more on this – particularly since in Figure 7 it seems that
the RF model is perform on par, or perhaps even better, than the BRT.

> TODO fixed with new validation set

## Specific comments

L9: Add a brief definition of connectance.

> Added

L31: Should the definition of Informedness also be written as an equation?

> Added

L35-38: An additional approach that might be worthwhile considering for
assessing overall performance would be to estimate the logistic regression
slope between, logit-transformed, predicted probabilities of occurrence and
occurrences of interactions in the testing data. Slopes close to 1 would
suggest that your model correctly predicts the proportion of interactions that
would be observed given your data. Nice features of this approach are that (1)
you can use e.g. residual distributions to assess how well your predictions
match the data along the range of predicted values, (2) you don’t have as many
moving parts (tp, fp) as when estimating AUC and PR-AUC, (3) and you can
estimate the variation in observed interactions that is explained by your
predictions

L53: The comparison with SDMs is interesting. In SDMs the imbalance between
occurrences/absences can be huge when e.g. pseudo-absences/background data are
used in combination with species occurrence records. Here Steen et al., Methods
Ecol Evol. 2021;12:216–226 doi: 10.1111/2041-210X.13525 might provide
a valuable reference for how spatial thinning affects different models’
performances as well as provide a basis for discussing the ‘biasing’ approach
adopted in the article

> This is an excellent suggestion - I have added a discussion of this article
at TODO. More generally, I have moved the discussion of SDMs earlier in the
introduction, to provide more ecological grounding.

L80: Please check the bracketing around the Jordano, 2016a,b reference

> Fixed

L134: perhaps specify why grid exploration was performed on logit(x)
transformed values, and add that logit(x) = -10 corresponds to e.g. skill or
bias close to zero, and 10 is close to one

> This is an excellent suggestion - fixed.

L135: could you add a reference to the statement that connectance of ]0,0.5] is
within the range of typical connectance in empirical food webs

> TODO

L170: Intuitively I would think that the norm would be to use as much data as
one can spare to train models, before validating on the remaining testing data.
Could you add a motivation for using a 30/70 and not a 70/30, training/testing
split

> I have added a discussion of the specific reasons at TODO

L171-172: Please spell out the B’s in B(6,8) and B(2,8), e.g.: “[…]
beta-distributions with alpha-parameter values of 6 and 2, and beta parameter
values of 8, for vi and hj, respectively”

> Fixed

L168-179: Would it be possible to include a figure showing how interactions
depend on the combination of infectiousness rate for e.g. 5 levels of the
resistance trait, just to give the reader a visual impression of how species
niches are simulated

> TODO figure legend

L180: I attempted to write the simulations in R but didn’t understand how “we
use [vi,hj] as a feature vector […]” would influence the input in the models.
Using a data frame with the columns: Interaction, vi, and hj, RF models in
R reached almost perfect PR-AUCs and ROC-AUCs – indicating that I’m missing
something. i.e.

~~~
vi <- rbeta(100,6,8)
hj <- rbeta(100,2,8)
allPotentialSpeciesInteractions <- expand.grid(vi,hj)
fn.connectanceOnInteraction <- function(x)data.frame(Interaction = allPotentialSpeciesInteractions[,1]-x/2 <= allPotentialSpeciesInteractions[,2] & allPotentialSpeciesInteractions[,2] <= allPotentialSpeciesInteractions[,1]+x/2, Connectance = x, vi = allPotentialSpeciesInteractions[,1], hj = allPotentialSpeciesInteractions[,2])

SimData <- fn.connectanceOnInteraction(0.16)
~~~

> Not being a R user, I cannot comment on the code - this being said, I have
added a more detailed explanation of the structure of all models at TODO, and
TODO

`SimData` is a data frame with 10 000 rows, containing four columns: logical
vector for the presence of interactions, numeric vector for connectance;
numeric vector for vi; and numeric vector for hj. From the SimData I then
created training datasets (n = 3000) with varying proportions of
interaction-occurrences (bias), for building models and predicted onto the
remaining 7000 rows. But I suspect I missed something here, and am hoping it’s
not just me who would do so. Would it be possible to include a table in the
manuscript, maybe just in the appendix, showing what the dataset used for the
training and testing the models looked like (e.g. first 5 rows w column names)

> As mentioned in the above response, I have added an illustration of what the
data look like for the prediction - this should clarify the overall process.
I think that the issue in the reviewer's code is the inclusion of connectance
as a predictor, but I have not tested this assumption as it is unlikely to be
realized in practice.

L182-187: If I understand this correctly, then you have 10K unique
species-combination with either an interaction or lack thereof. From the 10K
species-combinations you randomly pick a fixed proportion (v) of 3000 data
points for which interactions occur, and then randomly pick 1-v*3000 data
points where no interaction occurred. So in the remaining 7000 data points
where will be a negative correlation between the number of interactions, so
that an increasing amount of balance in the training data results in an
increasing amount of imbalance in the testing data. I am therefore wondering if
the testing data should be subsampled to recreate the original imbalance, to
avoid the relative proportion of interactions in the testing data affecting the
resulting confusion matrix and derived metrics (MCC, etc.,)

> This is an excellent suggestion -- one of my issues with it is that in
practice, these models would be applied to datasets for which the actual class
imbalance is not the one used for training; that being said, the reviewer is
absolutely correct in mentioning that changing the training class imbalance
TODO 

L189: Add a motivation for why these four ML methods were selected and how they
differ – e.g. by explaining the most central ways in which they differ. I think
the BRT and RF and decision tree regressor form an intuitive group, all being
built from (or consisting of) decision trees, but assembled in different ways,
but I struggle a bit with why ridge regression and not e.g. SVM was used – or
the other methods assessed in Pichler et al., Methods Ecol Evol.
2020;11:281–293 doi: 10.1111/2041-210X.13329.

> TODO

L191: Earlier on you focus on classifiers but here I get the impression that
you used random forest regression, and not a classifier. If using a regressor
instead of a classifier (and then using class probabilities), It might be
worthwhile specifying why this choice was made and perhaps it would be
meaningful to compare the two?

> TODO

L192: Although the comparison between different models is not the main focus of
the paper, it does take up a central place. Ideally such a comparison would’ve
been based on the optimal settings/hyper-parameters for each model. With the
enormous amount of simulations, I understand the reasoning behind not searching
parameter-space for optimal models. Would it be possible to either (a) reduce
the number of simulations by e.g. using fewer variable-states for connectance
and bias and searching for optimal tuning settings? (b) searching for optimal
tuning settings for an ‘average’ dataset? (c) or briefly specify the default
settings for the four models in MLJ.jl, since the default settings differ
between programs and packages? If it is not feasible, or needed, to search for
optimal tuning then I think it should be stated if, and how, the models differ
in their sensitivity to tuning, and how this might influence results further
down.

> TODO specificy the models BUT point at very high performance, and simple
problem that makes the search less useful

L205: I struggle a bit with understanding how the ensemble model relates to the
four underlying models contribute to the ensemble model. From Figures 3-4 it
seems to me that the predicted probabilities of interactions must vary
non-linearly with the training set bias and connectance, with different slopes
for each of the four models. I would therefore suspect that the contributions
of each model to the ensemble model also varies non-linearly. To ease the
interpretation of the ensemble model, I wondering if if would it be possible to
identify the unique contribution of each underlying model to the predicted
output from the ensemble model?

> TODO

L209-214: please specify if you removed failed (i.e. meeting one of your
criteria) connectance-bias-combinations across all models, or just for the
model(s) which had failed.

> TODO

L223: ‘stared’ - > started

L228: “classifiers” please check that the wording is correct, i.e. if models
used clafficiation trees or regression trees.

L239: ‘withold’ -> ‘requires one to withhold […]’

L254: “[…] interactions do not exist starts gaining importance […]” I think
this is complicated by the way the subsampling was designeds: training data
having fewer and fewer ‘absences’ of interactions as connectance and bias
increases, while the testing data will have an increasing dominance of
‘absences’.

> TODO fixed

L260: Because model predictions were summed when generating the ensemble,
models that underpredict occurrences of interactions at certain levels of bias
and connectance, will have a smaller effect on the ensemble model at these
parameter state combinations. If would be useful to know how the tendency to
over/under predict varies between the models as a function of bias and
connectance. Here regression slopes from logistic GLMs on the occurrence of
interactions in the testing data as a function of the logit(predicted
probability of interaction) could be useful.

L273: it seems like there are some references missing here.

L284: Olito & Fox, Oikos 124: 428–436, 2015 doi: 10.1111/oik.01439 might be
a useful reference here.

L293: That network structure doesn’t necessarily relate to processes generating
pairwise-interactions is also discussed in Olito & Fox, Oikos 124: 428–436,
2015 doi: 10.1111/oik.01439 and Dormann et al., (2017). Identifying causes of
patterns in ecological networks: opportunities and limitations. Annual Review
of Ecology, Evolution, and Systematics, 48, 559-584.

L287: In the guidelines section I think it could be useful to discuss different
approaches for increasing ‘bias’ in the training data. One approach, as done in
this paper, is to increasing the proportion of ‘presences’ in the training data
at the expense of the proportion of presences in the testing data. An
alternative would be to split the data into testing and training, e.g. with
initially equal proportions of presences, and then apply different degrees of
thinning to the training data by randomly removing rows with absences of
interactions – thereby increasing the proportion of interaction occurrences
without affecting the structure of the testing data.

## Tables

Table 1: spell out the network metrices in the table legend.

## Figures

Figure 1: there seems to be a mix of terminologies used for the same metrics.
It would help the reader if the same terminology is used in the figure legend
as in the figure labels, and that figures appear in the same order as they are
mentioned in the legend.

Figure 2: the figures appear in another order than in the legend.

Figure 3: Consider mentioning Informedness before MCC so that the order is the
same in the legend as in the ‘legend-box’

Figure 4: Consider mentioning PR-AUC before ROC-AUC so that the order is the
same in the legend as in the ‘legend-box’

Figures 5-6: should these be in colour? Also the smoothed lines sometimes fall
outside the contour-lines. Perhaps add a brief explanation of what the smoothed
lines and contours represent.

# Reviewer 3

The manuscript uses machine learning methods to predict interspecific
interactions in ecological networks. As we gain scientific understanding of
natural, our ability to predict them should also increase. During the last
decades we have gained increasing undestanding of the structure and dynamics of
ecological interaction networks (the networks depicting the interactions among
species in ecological communities), our ability to predict interactions remains
limited. This manuscript offers a methodological toolkit that could help
increase our predictive ability.

I value the work reported in this manuscript and I view machine learning
methods as a promising approach to the prediction of species interactions. At
the same time, I think the manuscript would need substantial revision before it
can represent a useful set of guidelines for ecologists interested in applying
machine learning methods for predicting the structure of ecological networks.
Among the main limitations I found, I think the manuscript lacks of a proper
setup for readers to understand the context in which these methods can be
applied, the presentation of methods is often unclear, and the guidelines for
validating machine learning predictions are difficult to identify.

First, the manuscript lacks a proper introduction, which in my opinion would
make it very difficult for many readers to understand the ecological problem
that the author is trying to solve and its relevance for our understanding of
species interactions. The goal of the paper concerns the prediction of species
interactions, so I would have expected some context about species interactions
and their prediction, including references to previous studies attempting to
predict interactions, their advanges and their limitations. For example, what
kind of prediction are we talking about? Prediction in macroevolutionary
escales, regarding how clades will evolve in their ability to interact with
taxons in their and other clades? Or are we talking about ecological scales
regarding the prediction of interactions over temporal and/or spatial scales?
I know what the author has in mind, but other readers will have a hard time
understanding the biological, ecological, and evolutionary scope of the methods
presented in the manuscript. Instead, the manuscript starts with the accuracy
paradox, which I agree represents a key idea for the current work, but it
almost seems as if the manuscript were missing a couple of pages that help the
reader get to this paradox (I actually checked several times if I hadn't
overlooked those introductory pages).

Second, I found the presentation of the different measures of performance a bit
confusing and difficult to follow. You mention (line 26) three threshold
measures---k, informedness and MMC---and two ranking metrics---ROC-AUC and
PR-AUC. Then you present equations for k (first equation), informedness, MCC
(second equation), and F1. You hadn't mentioned F1 among the five metrics, and
the equation for informedness is given as an in-line equation, in contrast to
the other metrics, for which you give each equation in its own line. Then, you
describe the ROC and PR cuves, without actually defining them (you had defined
ROC-AUC and PR-AUC, but never precisely define ROC and PR). Then you say that
"F1 has ties to the PR curve", which also sounds inaccurate, and also mention
differences between ROC and PR by referring what they don't do (PR "does not
prominently account for the size of the true negative compartments"), but not
what they actually do. I also found a need for greater clarity in most
mathematical definitions given throughout the text, especially in the section
"Baseline values" (lines 103-166). Please provide proof of each mathematical
definition, or the appropriate references providing such proofs. For example,
why is it that the predictions of a no-skill classifier conform to p = rho (1
- rho), the confusion matrix M is defined by the Hadamard product of vectors
o and p, the skill adjusted confusion matrix is the Hadamard product of M and
S, accuracy is Tr(c)/sum(M), etc.?

Third, the numerical experiments on training strategy are also difficult to
follow. For example, what does it mean that networks are generated by picking
a random infectiousness trait and a resistance trait (line 170-172)?
Infectiousness of what and resistance to what? And what does a "feature vector"
(line 180) represent and why does it make the simulated network more difficult
to predict? What is an "adjacency matrix" (a key concept to understand what the
author is talking about!)? Also, if connectance is a proportion, how can it be
greater than 3 (lines 213-214)?

Fourth, the results are also sometimes obscure and difficult to follow. For
example, in Fig. 1, the legend states that it shows "Consequences of changing
the classifier skills (s) and bias (s)" on "accuracy, F1 , postive predictive
value, and K", but the panels show F1, informedness, MCC and K; where are
accuracy and positive predictive value shown?

Fifth, I also had a hard time identifying and understanding the guidelines for
the assesment of network predictive models offered in the last section of the
manuscript. All the four "guidelines" look more as conclusions full of caveats,
from which the readers may, or may not, derive their own, unstated guidelines
about how to proceed. I think the author needs to make a greater effort here in
presenting more clearly identified guidelines.

So I think that the manuscript needs an introduction, more clarity in the
presentation of the methods and results, and a clearer presentation of the
guidelines, which, according to the title, should represent the key part of the
manuscript for many readers who may consider using these methods; a summary
table with these guidelines could be useful. I also suggest providing a figure
summarizing the methodology, identifying the different stepts involving the
prediction of interactions with machine learning techniques as developed in
this manuscript. And I would also find informative if the manuscript included
a section with an example with a real network, so that readers can see how
these methods would apply to real-world data.

In addition to the above general comments, here go a few additional specific
suggestions:

Line 25: You say you will focus on five measure to evaluation classification
tasks. Why this particular set of measures?

Lines 29-35: Please add the left hand side of the equality of each equation
(for example, add "x = " for the first equation), and number all equations, so
all readers can navigate more easily through the text and the equations.

Line 33: "event"

Line 49: "latter"

Line 95: Baseline values of what? Please use a more self explanatory title.

Line 96: Please define connectance, as not all readers will be familiar with
this concept.

Line 135: Please reverse opening square bracket.

Line 146: "bias"

Line 259: "especially"

Line 262: "example"

Line 263: "Does"

Line 273: missing references
