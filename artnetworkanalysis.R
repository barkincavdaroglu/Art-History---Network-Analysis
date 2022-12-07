# Barkin Cavdaroglu
require("statnet")
require("igraph")
require("ergm")
require("intergraph")
require("blockmodeling")
library(tcltk)

library(stringr)


# Part 1 - Bipartite Projection
EdgeList <- read.csv("data.csv",header=TRUE)
Graph_1 <- graph_from_edgelist(as.matrix(EdgeList))

V(Graph_1)$type <- V(Graph_1)$name %in% EdgeList[,1]
BipartiteMatrix <- as_incidence_matrix(Graph_1)
t(BipartiteMatrix)
ProjectionMatrix1 <- BipartiteMatrix %*% t(BipartiteMatrix)
diag(ProjectionMatrix1)<-0

ProjectionGraph1 <- graph_from_adjacency_matrix(ProjectionMatrix1, 
                                                mode = "undirected", 
                                                weighted = TRUE)

tkplot(ProjectionGraph1, canvas.width=1200, canvas.height=1000,vertex.size = 3,  vertex.label.cex=0.9,
     edge.color=E(ProjectionGraph1)$weight,edge.width=E(ProjectionGraph1)$weight)

pageranks <- page_rank(ProjectionGraph1, weights = NULL)
eigen_centralities <- eigen_centrality(ProjectionGraph1, weights = NULL)$vector
print(which(eigen_centralities > 0.5))
print(max(pageranks[[1]]))
degree(ProjectionGraph1)

# Performance Art has the highest eigenvector centrality score. The code below
# creates an ego network of order 2 for Performance Art.
BodyArt_Subgraph <- make_ego_graph(ProjectionGraph1, nodes=c("Performance Art"), order=2)[[1]]
BodyArt_Subgraph <- connect(BodyArt_Subgraph, order=12)
tkplot(BodyArt_Subgraph, canvas.width=1200, canvas.height=1000,vertex.size = 3,  vertex.label.cex=0.9,
       edge.color=E(BodyArt_Subgraph)$weight,edge.width=E(BodyArt_Subgraph)$weight)

cuts <- articulation_points(ProjectionGraph1)
cut_subgraph <- induced_subgraph(ProjectionGraph1, cuts)
print(cut_subgraph)
degree(cut_subgraph)


# Part 2 - Undirected Weighted Graph
# This will be used as the data for plotting
NetworkEdges <- read.csv("data_3.csv",header=TRUE)
relations <- data.frame(from=NetworkEdges$name,
                        to=NetworkEdges$edge,
                        movement=NetworkEdges$movement)
Graph_for_plot <- graph_from_data_frame(relations, directed=FALSE)

# This will be used as the data for analysis
NetworkEdges_2 <- read.csv("data_2.csv", header=TRUE)
relations2 <- data.frame(from=NetworkEdges_2$name,
                         to=NetworkEdges_2$edge,
                         movement=NetworkEdges_2$movement)
Graph_2 <-graph_from_data_frame(relations2, directed=FALSE)

articulation_points(Graph_2)
assortativity_degree(Graph_2)
centr_eigen(Graph_2)
eigen_centrality(Graph_2)

E(Graph_for_plot)$weight <- NetworkEdges$weight

plot(Graph_for_plot,vertex.size = 2, vertex.label = NA, vertex.label.cex=0.5,
     edge.color=E(Graph_for_plot)$weight,edge.width=E(Graph_for_plot)$weight)

plot(Graph_2, vertex.size = 2, vertex.label = NA, vertex.label.cex=0.5, edge.label = E(Graph)$movement)

# Connected Components Analysis
art_components <- decompose.graph(Graph_2)

mean_distances_components <- c()
average_degree_centralities_components <- c()
number_of_vertices_components <- c()
number_of_edges_components <- c()

for (a_g in art_components) {
  curr_mean_distance <- mean_distance(a_g)
  curr_degree_centralities <- centr_degree(a_g)
  
  average_degree_centrality <- Reduce("+", curr_degree_centralities$res) / length(curr_degree_centralities$res) 
  mean_distances_components <- append(mean_distances_components, curr_mean_distance)
  average_degree_centralities_components <- append(average_degree_centralities_components, average_degree_centrality)
  number_of_vertices_components <- append(number_of_vertices_components, vcount(a_g))
  number_of_edges_components <- append(number_of_edges_components, ecount(a_g))

}

measure_table <- data.frame("# of Vertices" = number_of_vertices_components,
                            "# of Edges" = number_of_edges_components,
                            "Avg Path Length" = mean_distances_components,
                            "Avg Deg Centrality" = average_degree_centralities_components)
print(measure_table)


# Clustering

ebc <- edge.betweenness.community(Graph_2, directed=F)
mods <- sapply(0:ecount(Graph_2), function(i){
  g <- igraph::delete.edges(Graph_2, ebc$removed.edges[seq(length=i)])
  cl <- clusters(g)$membership
  modularity(Graph_2,cl)
})
g <- igraph::delete.edges(Graph_2, ebc$removed.edges[seq(which.max(mods)-1)])
plot(as.dendrogram(ebc))
plot(ebc$modularity)

ClusterMembership = clusters(g)$membership
V(Graph_2)$color= ClusterMembership

for(i in unique(V(Graph_2)$color)) {
  GroupV <- which(V(Graph_2)$color == i)
  a <- c()
  if (length(GroupV) > 2) {
    graph_v <- induced_subgraph(Graph_2, GroupV)
    for (v_ in GroupV) {
      a <- append(a, vertex_attr(Graph_2, index=c(v_))$name)
    }
    for (e in E(graph_v)$movement) {
      a <- append(a, e)
    }
    b <- induced_subgraph(Graph_1, a)
    V(b)$type <- V(b)$name %in% EdgeList[,1]
    BipartiteMatrix_gv <- as_incidence_matrix(b)
    t(BipartiteMatrix_gv)
    ProjectionMatrix1_gv <- BipartiteMatrix_gv %*% t(BipartiteMatrix_gv)
    diag(ProjectionMatrix1_gv)<-0
    
    ProjectionGraph1_gv <- graph_from_adjacency_matrix(ProjectionMatrix1_gv, 
                                                    mode = "undirected",
                                                    weighted = TRUE)
    
    tkplot(ProjectionGraph1_gv, canvas.width=1200, canvas.height=1000,vertex.size = 3,  vertex.label.cex=0.9,
           edge.color=E(ProjectionGraph1_gv)$weight,edge.width=E(ProjectionGraph1_gv)$weight)
    
    edge_attributes_v <- edge_attr(graph_v)
    art_mov_str <- c()
    art_mov_count <- c()
    unique_art_movs <- unique(edge_attributes_v$movement)

    for (mm in unique_art_movs) {
      cnt <- sum(str_count(edge_attributes_v$movement, mm))
      art_mov_str <- append(art_mov_str, mm)
      art_mov_count <- append(art_mov_count, cnt)
    }
    curr_mean_distance <- mean_distance(graph_v)
    curr_degree_centralities <- centr_degree(graph_v)
    
    average_degree_centrality <- Reduce("+", curr_degree_centralities$res) / length(curr_degree_centralities$res) 
    
    art_mov_df <- data.frame(movements = art_mov_str, count = art_mov_count)
    print(art_mov_df)
    print(average_degree_centrality)
    print(curr_mean_distance)
  }
} 
