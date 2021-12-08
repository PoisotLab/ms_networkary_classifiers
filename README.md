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
network is a column vector $\mathbf{o}^T = [\rho (1-\rho)]$ (we can safely drop
the $S^2$ terms, as we will work on the confusion matrix, which ends up
expressing *relative* values).

In order to write the values of the confusion matrix for a hypothetical
classifier, we need to define two characteristics: its skill, and its bias.
Skill, here, refers to the propensity of the classifier to get the correct
answer (*i.e.* to assign interactions where they are, and to not assign them
where they are not). A no-skill classifier guesses at random, *i.e.* it will
guess interactions with a probability $\rho$. The predictions of a no-skill
classifier can be expressed as a row vector $\mathbf{p} = [\rho (1-\rho)]$. The
confusion matrix $\mathbf{M}$ for a no-skill classifier is given by the
element-wise product of these vectors $\mathbf{o} \odot \mathbf{p}$, *i.e.*

$$
\mathbf{M} = \begin{pmatrix}
    \rho^2 & \rho (1-\rho) \\
    (1-\rho) \rho & (1-\rho)^2
\end{pmatrix} \,.
$$

In order to regulate the skill of this classifier, we can define a skill matrix
$\mathbf{S}$ with diagonal elements equal to $s$, and off-diagonal elements
equal to $(1-s)$, and re-express the skill-adjusted confusion matrix as
$\mathbf{M} \odot \mathbf{S}$, *i.e.*

$$
\begin{pmatrix}
    \rho^2 & \rho (1-\rho) \\
    (1-\rho) \rho & (1-\rho)^2
\end{pmatrix} \odot \begin{pmatrix}
    s & (1-s) \\
    (1-s) & s
\end{pmatrix} \,.
$$

Note that when $s=0$, $\text{Tr}(\mathbf{M}) = 0$ (the classifier is *always*
wrong), when $s=0.5$, the classifier is no-skill and guesses at random, and when
$s=1$, the classifier is perfect.

The second element we can adjust in this hypothetical classifier is its bias,
specifically its tendency to over-predict interactions. Like above, we can do so
by defining a bias matrix $\mathbf{B}$, where interactions are over-predicted
with probability $b$, and express the final classifier confusion matrix as
$\mathbf{M}\odot \mathbf{S}\odot \mathbf{B}$, *i.e.*

$$
\begin{pmatrix}
    \rho^2 & \rho (1-\rho) \\
    (1-\rho) \rho & (1-\rho)^2
\end{pmatrix} \odot \begin{pmatrix}
    s & (1-s) \\
    (1-s) & s
\end{pmatrix} \odot \begin{pmatrix}
    b & b \\
    (1-b) & (1-b)
\end{pmatrix}\,.
$$

The final expression for the confusion matrix in which we can regulate the skill
and the bias is

$$
\mathbf{C} = \begin{pmatrix}
    s\times b\times \rho^2 & (1-s)\times b\times \rho (1-\rho) \\
    (1-s)\times (1-b)\times (1-\rho) \rho & s\times (1-b)\times (1-\rho)^2
\end{pmatrix} \,.
$$

# Numerical experiments

## Effect of training set on performance

## Required amount of positives to get the best performance

# Guidelines for prediction

# References