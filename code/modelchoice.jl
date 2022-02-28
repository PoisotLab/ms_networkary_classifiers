# these regression machines go brrr as f u c k
DecisionTree = @load DecisionTreeRegressor pkg = DecisionTree verbosity=0
RandomForest = @load RandomForestRegressor pkg = DecisionTree verbosity=0
BoostedRegressor = @load EvoTreeRegressor pkg = EvoTrees verbosity=0
KNNRegressor = @load KNNRegressor pkg = NearestNeighborModels verbosity=0

# Object for candidate models
candidate_models = [
    Symbol("Decision tree") => DecisionTree(),
    :BRT => BoostedRegressor(),
    Symbol("Random Forest") => RandomForest(),
    :kNN => KNNRegressor(),
]
