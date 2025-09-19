//! Core quantum state management for version control
//! Implements superposition of commits until observation/merge

use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use uuid::Uuid;
use sha3::{Digest, Sha3_256};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuantumCommit {
    pub id: Uuid,
    pub content_hash: String,
    pub superposition_states: HashMap<String, f64>, // branch -> probability
    pub entangled_commits: HashSet<Uuid>,
    pub collapsed: bool,
    pub timestamp: u64,
    pub changes: Vec<FileChange>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileChange {
    pub path: String,
    pub operation: ChangeType,
    pub content_delta: Vec<u8>,
    pub line_mappings: Vec<(usize, usize)>, // (old_line, new_line)
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ChangeType {
    Insert,
    Delete, 
    Modify,
    Move(String), // new path
}

pub struct QuantumRepository {
    commits: HashMap<Uuid, QuantumCommit>,
    branch_heads: HashMap<String, Uuid>,
    entanglement_graph: petgraph::Graph<Uuid, f64>,
    superposition_index: HashMap<String, HashSet<Uuid>>, // file_path -> commits in superposition
}

impl QuantumRepository {
    pub fn new() -> Self {
        Self {
            commits: HashMap::new(),
            branch_heads: HashMap::new(), 
            entanglement_graph: petgraph::Graph::new(),
            superposition_index: HashMap::new(),
        }
    }

    /// Create commit existing in multiple branch states simultaneously
    pub fn commit_superposition(
        &mut self,
        changes: Vec<FileChange>,
        branch_probabilities: HashMap<String, f64>,
    ) -> Result<Uuid, QuantumError> {
        // Validate probability distribution
        let total_prob: f64 = branch_probabilities.values().sum();
        if (total_prob - 1.0).abs() > 0.001 {
            return Err(QuantumError::InvalidProbabilityDistribution(total_prob));
        }

        let commit_id = Uuid::new_v4();
        let content_hash = self.calculate_content_hash(&changes);
        
        // Find commits that will become entangled due to file overlap
        let entangled_commits = self.calculate_entanglements(&changes);

        let quantum_commit = QuantumCommit {
            id: commit_id,
            content_hash,
            superposition_states: branch_probabilities.clone(),
            entangled_commits,
            collapsed: false,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            changes: changes.clone(),
        };

        // Update superposition index for affected files
        for change in &changes {
            self.superposition_index
                .entry(change.path.clone())
                .or_insert_with(HashSet::new)
                .insert(commit_id);
        }

        // Add entanglement edges in graph
        let commit_node = self.entanglement_graph.add_node(commit_id);
        for &entangled_id in &entangled_commits {
            if let Some(entangled_node) = self.find_node_by_commit(entangled_id) {
                let entanglement_strength = self.calculate_entanglement_strength(&changes, entangled_id)?;
                self.entanglement_graph.add_edge(commit_node, entangled_node, entanglement_strength);
            }
        }

        self.commits.insert(commit_id, quantum_commit);
        Ok(commit_id)
    }

    /// Quantum measurement - collapse superposition to single branch reality
    pub fn observe_branch(&mut self, branch_name: &str) -> Result<Uuid, QuantumError> {
        let commits_in_superposition: Vec<_> = self.commits
            .values()
            .filter(|c| !c.collapsed && c.superposition_states.contains_key(branch_name))
            .map(|c| c.id)
            .collect();

        let mut rng = fastrand::Rng::new();
        let mut collapsed_commits = Vec::new();

        for commit_id in commits_in_superposition {
            let commit = self.commits.get_mut(&commit_id).unwrap();
            let probability = commit.superposition_states[branch_name];
            
            // Quantum measurement - probabilistic collapse
            if rng.f64() < probability {
                commit.collapsed = true;
                
                // Remove from other branch probabilities
                let other_branches: Vec<_> = commit.superposition_states
                    .keys()
                    .filter(|&k| k != branch_name)
                    .cloned()
                    .collect();
                
                for branch in other_branches {
                    commit.superposition_states.remove(&branch);
                }

                collapsed_commits.push(commit_id);
                self.branch_heads.insert(branch_name.to_string(), commit_id);
            }
        }

        // Handle entanglement collapse - when one commit collapses, entangled commits are affected
        self.cascade_entanglement_collapse(&collapsed_commits)?;

        self.branch_heads.get(branch_name)
            .copied()
            .ok_or(QuantumError::BranchNotFound(branch_name.to_string()))
    }

    fn calculate_entanglements(&self, changes: &[FileChange]) -> HashSet<Uuid> {
        let mut entangled = HashSet::new();
        
        for change in changes {
            if let Some(commits_affecting_file) = self.superposition_index.get(&change.path) {
                for &commit_id in commits_affecting_file {
                    if let Some(commit) = self.commits.get(&commit_id) {
                        if !commit.collapsed {
                            entangled.insert(commit_id);
                        }
                    }
                }
            }
        }
        
        entangled
    }

    fn calculate_entanglement_strength(&self, changes: &[FileChange], other_commit_id: Uuid) -> Result<f64, QuantumError> {
        let other_commit = self.commits.get(&other_commit_id)
            .ok_or(QuantumError::CommitNotFound(other_commit_id))?;

        let mut overlap_score = 0.0;
        let mut total_changes = changes.len() as f64;

        for change in changes {
            for other_change in &other_commit.changes {
                if change.path == other_change.path {
                    // Calculate line overlap
                    let line_overlap = self.calculate_line_overlap(&change.line_mappings, &other_change.line_mappings);
                    overlap_score += line_overlap;
                }
            }
        }

        Ok((overlap_score / total_changes).min(1.0))
    }

    fn calculate_line_overlap(&self, mappings1: &[(usize, usize)], mappings2: &[(usize, usize)]) -> f64 {
        let set1: HashSet<_> = mappings1.iter().collect();
        let set2: HashSet<_> = mappings2.iter().collect();
        
        let intersection_size = set1.intersection(&set2).count() as f64;
        let union_size = set1.union(&set2).count() as f64;
        
        if union_size == 0.0 { 0.0 } else { intersection_size / union_size }
    }

    fn cascade_entanglement_collapse(&mut self, collapsed_commits: &[Uuid]) -> Result<(), QuantumError> {
        use petgraph::algo::dijkstra;
        
        for &collapsed_id in collapsed_commits {
            if let Some(node_index) = self.find_node_by_commit(collapsed_id) {
                // Find all connected commits (entangled)
                let reachable = dijkstra(&self.entanglement_graph, node_index, None, |_| 1);
                
                for (connected_node, _distance) in reachable {
                    let connected_commit_id = self.entanglement_graph[connected_node];
                    
                    if let Some(connected_commit) = self.commits.get_mut(&connected_commit_id) {
                        if !connected_commit.collapsed {
                            // Reduce probabilities in entangled commits due to quantum interference
                            for (_, prob) in connected_commit.superposition_states.iter_mut() {
                                *prob *= 0.8; // Interference dampening factor
                            }
                        }
                    }
                }
            }
        }
        
        Ok(())
    }

    fn find_node_by_commit(&self, commit_id: Uuid) -> Option<petgraph::graph::NodeIndex> {
        self.entanglement_graph
            .node_indices()
            .find(|&idx| self.entanglement_graph[idx] == commit_id)
    }

    fn calculate_content_hash(&self, changes: &[FileChange]) -> String {
        let mut hasher = Sha3_256::new();
        for change in changes {
            hasher.update(&change.path);
            hasher.update(&change.content_delta);
        }
        format!("{:x}", hasher.finalize())
    }
}

#[derive(Debug, thiserror::Error)]
pub enum QuantumError {
    #[error("Invalid probability distribution: {0}, must sum to 1.0")]
    InvalidProbabilityDistribution(f64),
    #[error("Commit not found: {0}")]
    CommitNotFound(Uuid),
    #[error("Branch not found: {0}")]
    BranchNotFound(String),
    #[error("Quantum decoherence detected")]
    QuantumDecoherence,
}