%============================================================
% probabilistic_model.pl - Probabilistic Graphical Models
%
% Convert execution graphs to probabilistic models for:
%   - Bayesian inference over execution paths
%   - PyMC model generation
%   - Stan model generation
%   - Path probability calculations
%============================================================

:- module(probabilistic_model, [
    % Probabilistic graphical model
    graph_to_pgm/2,           % graph_to_pgm(+Graph, -PGM) - Convert to Bayesian network structure
    path_probability/3,       % path_probability(+Graph, +Path, -Prob)
    sample_path/4,            % sample_path(+Graph, +InputDist, -Path, -Prob)

    % Probabilistic programming exports
    pgm_to_pymc/2,            % pgm_to_pymc(+PGM, -PythonCode) - Generate PyMC model
    pgm_to_stan/2,            % pgm_to_stan(+PGM, -StanCode) - Generate Stan model
    pgm_to_python_package/3   % pgm_to_python_package(+PGM, +Graph, -Files) - Complete package
]).

:- use_module(ml_export).

%------------------------------------------------------------
% Probabilistic Graphical Model Conversion
%------------------------------------------------------------

%% graph_to_pgm(+Graph, -PGM) is det.
%
% Convert execution graph to a Probabilistic Graphical Model structure.
% Useful for probabilistic inference over execution paths.
%
% PGM structure:
%   pgm{
%     variables: [var{name, type, parents, domain}],
%     factors: [factor{vars, table}],
%     observed: [name-value pairs]
%   }

graph_to_pgm(Graph, PGM) :-
    Graph = graph{nodes: Nodes, edges: Edges, metadata: _},
    % Extract branch nodes as random variables
    findall(
        var{id: N1, name: VarName, type: branch, parents: Parents, domain: [true, false]},
        (member(node(N, branch, node_data{data: D, timestamp: _}), Nodes),
         N1 is N - 1,
         format(atom(VarName), 'branch_~d', [N1]),
         % Find parent branch nodes (through control flow)
         findall(P1,
             (member(edge(P, N, control), Edges),
              member(node(P, branch, _), Nodes),
              P1 is P - 1),
             Parents)),
        BranchVars),
    % Extract assignment nodes as observed variables (when values known)
    findall(
        var{id: N1, name: VarName, type: assign, parents: [], domain: continuous},
        (member(node(N, assign, node_data{data: D, timestamp: _}), Nodes),
         N1 is N - 1,
         D.var = AssignVar,
         format(atom(VarName), 'assign_~w_~d', [AssignVar, N1])),
        AssignVars),
    append(BranchVars, AssignVars, AllVars),
    % Create uniform prior factors for branches (can be updated with observations)
    findall(
        factor{vars: [VarName], table: [[true, 0.5], [false, 0.5]]},
        member(var{name: VarName, type: branch, parents: [], domain: _}, BranchVars),
        PriorFactors),
    PGM = pgm{
        variables: AllVars,
        factors: PriorFactors,
        observed: []
    }.

%------------------------------------------------------------
% Path Probability
%------------------------------------------------------------

%% path_probability(+Graph, +Path, -Probability) is det.
%
% Calculate probability of a specific execution path given branch probabilities.
% Path is a list of branch decisions: [branch(NodeId, true/false), ...]
% Assumes uniform 0.5 probability for each branch by default.

path_probability(_, [], 1.0).
path_probability(Graph, [branch(_NodeId, _Decision)|Rest], Prob) :-
    % Default: uniform probability
    BranchProb = 0.5,
    path_probability(Graph, Rest, RestProb),
    Prob is BranchProb * RestProb.

%% sample_path(+Graph, +InputDist, -Path, -Probability) is det.
%
% Sample an execution path given an input distribution.
% InputDist: dict mapping variable names to distributions
%            e.g., input_dist{'X': uniform(0, 100), 'Y': normal(50, 10)}
% Returns the sampled Path and its Probability.
%
% Note: This is a stub - full implementation would require:
%       1. Symbolic execution to determine branch conditions
%       2. Constraint solving to check path feasibility
%       3. Integration with a probabilistic programming backend

sample_path(Graph, _InputDist, Path, Probability) :-
    % Collect all branch nodes
    Graph = graph{nodes: Nodes, edges: _, metadata: _},
    findall(NodeId,
        member(node(NodeId, branch, _), Nodes),
        BranchNodes),
    % For now: sample uniformly from recorded decisions
    maplist(sample_branch_uniform, BranchNodes, Path),
    path_probability(Graph, Path, Probability).

sample_branch_uniform(NodeId, branch(NodeId, Decision)) :-
    random(R),
    ( R < 0.5 -> Decision = true ; Decision = false ).

%------------------------------------------------------------
% PyMC Export
%------------------------------------------------------------

%% pgm_to_pymc(+PGM, -PythonCode) is det.
%
% Generate PyMC model code from PGM structure.
% The generated code can be saved to a .py file and executed.
%
% Usage in Python:
%   exec(open('model.py').read())
%   with model:
%       trace = pm.sample(1000)
%       # Analyze posterior over branch probabilities

pgm_to_pymc(PGM, PythonCode) :-
    PGM = pgm{variables: Vars, factors: Factors, observed: Observed},
    % Generate imports
    Imports = "import pymc as pm\nimport numpy as np\nimport arviz as az\n\n",
    % Generate model
    generate_pymc_model(Vars, Factors, Observed, ModelCode),
    atomics_to_string([Imports, ModelCode], PythonCode).

generate_pymc_model(Vars, Factors, Observed, ModelCode) :-
    % Separate branch vars from assign vars
    include(is_branch_var, Vars, BranchVars),
    include(is_assign_var, Vars, AssignVars),
    % Generate variable declarations
    maplist(pymc_branch_var, BranchVars, BranchDecls),
    maplist(pymc_assign_var, AssignVars, AssignDecls),
    % Generate observations if any
    generate_pymc_observations(Observed, ObsCode),
    % Combine
    atomics_to_string([
        "# Execution Path Model\n",
        "# Branch nodes are Bernoulli random variables\n",
        "# Assign nodes track variable values\n\n",
        "model = pm.Model()\n\n",
        "with model:\n",
        "    # Prior probabilities for each branch\n",
        "    # These can be updated based on input distributions\n\n"
    ], Header),
    atomics_to_string(BranchDecls, BranchCode),
    atomics_to_string(AssignDecls, AssignCode),
    atomics_to_string([
        Header,
        BranchCode,
        "\n    # Variable assignments (for conditioning)\n",
        AssignCode,
        ObsCode,
        "\n",
        "# Sample from the model\n",
        "# with model:\n",
        "#     trace = pm.sample(2000, return_inferencedata=True)\n",
        "#     az.plot_posterior(trace)\n"
    ], ModelCode),
    % Suppress unused variable warnings
    _ = Factors.

is_branch_var(var{type: branch, name: _, id: _, parents: _, domain: _}).
is_assign_var(var{type: assign, name: _, id: _, parents: _, domain: _}).

pymc_branch_var(var{name: Name, id: Id, parents: Parents, domain: _}, Code) :-
    ( Parents = []
    -> % Root branch - use Beta prior for probability
       format(string(Code),
           "    # Branch ~d: ~w\n    p_~w = pm.Beta('p_~w', alpha=1, beta=1)  # Uniform prior\n    ~w = pm.Bernoulli('~w', p=p_~w)\n\n",
           [Id, Name, Name, Name, Name, Name, Name])
    ;  % Conditional branch - depends on parent branches
       format(string(Code),
           "    # Branch ~d: ~w (conditional on parents: ~w)\n    p_~w = pm.Beta('p_~w', alpha=1, beta=1)\n    ~w = pm.Bernoulli('~w', p=p_~w)\n\n",
           [Id, Name, Parents, Name, Name, Name, Name, Name])
    ).

pymc_assign_var(var{name: Name, id: Id, parents: _, domain: _}, Code) :-
    format(string(Code),
        "    # Assignment ~d: ~w\n    # ~w = pm.Normal('~w', mu=0, sigma=10)  # Uncomment to model\n\n",
        [Id, Name, Name, Name]).

generate_pymc_observations([], "").
generate_pymc_observations(Observed, Code) :-
    Observed \= [],
    maplist(pymc_observation, Observed, ObsCodes),
    atomics_to_string(["\n    # Observed values\n" | ObsCodes], Code).

pymc_observation(Name-Value, Code) :-
    format(string(Code), "    pm.set_data({'~w_obs': ~w})\n", [Name, Value]).

%------------------------------------------------------------
% Stan Export
%------------------------------------------------------------

%% pgm_to_stan(+PGM, -StanCode) is det.
%
% Generate Stan model code from PGM structure.
% Save to a .stan file and compile with CmdStan or PyStan.
%
% Usage:
%   import cmdstanpy
%   model = cmdstanpy.CmdStanModel(stan_file='model.stan')
%   fit = model.sample(data={'N_branches': 5, 'observed_branches': [1,0,1,1,0]})

pgm_to_stan(PGM, StanCode) :-
    PGM = pgm{variables: Vars, factors: _, observed: _},
    include(is_branch_var, Vars, BranchVars),
    length(BranchVars, _NumBranches),
    generate_stan_model(BranchVars, StanCode).

generate_stan_model(BranchVars, StanCode) :-
    % Generate branch parameter names for comments
    maplist(branch_var_name, BranchVars, BranchNames),
    atomics_to_string(BranchNames, BranchNamesStr),
    format(string(StanCode),
'// Execution Path Model
// Generated from Clarion interpreter trace
// Branch variables: ~w

data {
  int<lower=0> N_branches;           // Number of branch points
  int<lower=0> N_observations;       // Number of observed executions
  array[N_observations, N_branches] int<lower=0, upper=1> observed_paths;  // Observed branch decisions
}

parameters {
  // Prior probability for each branch taking the "true" path
  vector<lower=0, upper=1>[N_branches] branch_probs;
}

model {
  // Weakly informative priors (Beta(1,1) = Uniform)
  branch_probs ~ beta(1, 1);

  // Likelihood of observed paths
  for (obs in 1:N_observations) {
    for (b in 1:N_branches) {
      observed_paths[obs, b] ~ bernoulli(branch_probs[b]);
    }
  }
}

generated quantities {
  // Sample a new path from the posterior
  array[N_branches] int<lower=0, upper=1> sampled_path;
  for (b in 1:N_branches) {
    sampled_path[b] = bernoulli_rng(branch_probs[b]);
  }

  // Path probability (product of branch probabilities)
  real path_prob = 1.0;
  for (b in 1:N_branches) {
    path_prob = path_prob * (sampled_path[b] == 1 ? branch_probs[b] : 1 - branch_probs[b]);
  }
}
', [BranchNamesStr]).

branch_var_name(var{name: Name, id: _, parents: _, domain: _, type: _}, NameStr) :-
    format(string(NameStr), "~w ", [Name]).

%------------------------------------------------------------
% Complete Python Package Export
%------------------------------------------------------------

%% pgm_to_python_package(+PGM, +Graph, -Files) is det.
%
% Generate a complete Python package for probabilistic path analysis.
% Files is a list of filename-content pairs.

pgm_to_python_package(PGM, Graph, Files) :-
    pgm_to_pymc(PGM, PymcCode),
    pgm_to_stan(PGM, StanCode),
    graph_to_numpy_json(Graph, GraphJson),
    generate_analysis_script(AnalysisScript),
    Files = [
        'model_pymc.py' - PymcCode,
        'model.stan' - StanCode,
        'graph.json' - GraphJson,
        'analyze_paths.py' - AnalysisScript
    ].

generate_analysis_script(Script) :-
    Script = '#!/usr/bin/env python3
"""
Execution Path Analysis Script
Generated from Clarion interpreter trace

This script demonstrates how to:
1. Load the execution graph
2. Fit probabilistic models to observed paths
3. Sample new paths from the posterior
4. Estimate path coverage
"""

import json
import numpy as np

# Load graph data
with open("graph.json") as f:
    graph = json.load(f)

print(f"Loaded graph with {graph[\'num_nodes\']} nodes, {graph[\'num_edges\']} edges")
print(f"Branch nodes: {len(graph[\'branch_nodes\'])}")

# Extract branch decisions from observed executions
# In practice, you would collect these from multiple traced runs
branch_nodes = graph["branch_nodes"]
n_branches = len(branch_nodes)

print(f"\\nBranch conditions:")
for b in branch_nodes:
    print(f"  Node {b[\'node\']}: {b[\'condition\']} -> {b[\'value\']}")

# Option 1: Use PyMC for Bayesian inference
def fit_pymc_model(observed_paths):
    """
    Fit a PyMC model to observed execution paths.

    observed_paths: list of lists, each inner list is [0/1] for each branch
    """
    try:
        import pymc as pm
        import arviz as az

        observed = np.array(observed_paths)
        n_obs, n_branches = observed.shape

        with pm.Model() as model:
            # Prior on branch probabilities
            branch_probs = pm.Beta("branch_probs", alpha=1, beta=1, shape=n_branches)

            # Likelihood
            pm.Bernoulli("obs", p=branch_probs, observed=observed)

            # Sample
            trace = pm.sample(2000, return_inferencedata=True)

        # Summarize posterior
        print("\\nPosterior branch probabilities:")
        summary = az.summary(trace, var_names=["branch_probs"])
        print(summary)

        return trace
    except ImportError:
        print("PyMC not installed. Install with: pip install pymc arviz")
        return None

# Option 2: Use Stan via CmdStanPy
def fit_stan_model(observed_paths):
    """
    Fit a Stan model to observed execution paths.
    """
    try:
        import cmdstanpy

        observed = np.array(observed_paths)
        n_obs, n_branches = observed.shape

        model = cmdstanpy.CmdStanModel(stan_file="model.stan")

        data = {
            "N_branches": n_branches,
            "N_observations": n_obs,
            "observed_paths": observed.tolist()
        }

        fit = model.sample(data=data, chains=4, iter_sampling=1000)

        print("\\nStan fit summary:")
        print(fit.summary())

        # Get sampled paths
        sampled = fit.stan_variable("sampled_path")
        print(f"\\nSampled {len(sampled)} paths from posterior")

        return fit
    except ImportError:
        print("CmdStanPy not installed. Install with: pip install cmdstanpy")
        return None

# Option 3: Simple frequentist estimate
def estimate_branch_probs(observed_paths):
    """
    Simple maximum likelihood estimate of branch probabilities.
    """
    observed = np.array(observed_paths)
    probs = observed.mean(axis=0)

    print("\\nMLE branch probabilities:")
    for i, p in enumerate(probs):
        print(f"  Branch {i}: P(true) = {p:.3f}")

    return probs

# Generate synthetic observations for demo
# In practice, these would come from traced executions
def generate_synthetic_observations(n_obs, branch_probs):
    """Generate synthetic path observations."""
    return np.random.binomial(1, branch_probs, size=(n_obs, len(branch_probs)))

# Demo
if __name__ == "__main__":
    # Use observed values from the trace if available
    if branch_nodes:
        # Single observation from trace
        observed_values = [1 if b["value"] else 0 for b in branch_nodes]
        print(f"\\nObserved path from trace: {observed_values}")

        # For demo: generate more synthetic observations
        # Assume true probabilities are close to observed
        true_probs = np.array([0.7 if v else 0.3 for v in observed_values])
        synthetic_obs = generate_synthetic_observations(50, true_probs)

        # Add the real observation
        all_obs = np.vstack([observed_values, synthetic_obs])

        print(f"\\nUsing {len(all_obs)} observations (1 real + {len(synthetic_obs)} synthetic)")

        # Estimate probabilities
        estimate_branch_probs(all_obs)

        # Uncomment to run full Bayesian inference:
        # fit_pymc_model(all_obs)
        # fit_stan_model(all_obs)
    else:
        print("No branch nodes found in graph")
'.
