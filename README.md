example on diagnostic test: rare events are hard to detect even with really good models

summary of model challenges for networks

introduction to the confusion matrix

list of problems to solve
- baseline values and response to bias
- effect of training set bias on performance
- which models need the least amount of interactions to work

summary of the results

# Baseline values 

In this section, we will assume a network of connectance $\rho$, *i.e.* having
$\rho S^2$ interactions (where $S$ is the species richness), and $(1-\rho) S^2$
non-interactions. Therefore, the vector describing the *true* state of the
network is $\mathbf{o}' = [\rho, (1-\rho)]$ (we can safely drop the $S^2$ terms,
as we will work on the confusion matrix, which ends up expressing *relative*
values).

In order to write the values of the confusion matrix for a hypothetical
classifier, we need to define two characteristics: its skill, and its bias.
Skill, here, refers to the propensity of the classifier to get the correct
answer (*i.e.* to assign interactions where they are, and to not assign them
where they are not). A no-skill classifier guesses at random, *i.e.* it will
guess interactions with a probability $\rho$.

# Numerical experiments

## Effect of training set on performance

## Required amount of positives to get the best performance

# Guidelines for prediction

# References