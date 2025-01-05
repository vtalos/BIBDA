import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import silhouette_score

def load_and_prepare_data(file_path):
    df = pd.read_csv(file_path)
    
    clustering_features = [
        'channel_view_count',
        'channel_subscriber_count',
        'channel_video_count'
    ]
    
    channel_data = df.drop_duplicates(subset='channel_id')[
        ['channel_id', 'video_category_id'] + clustering_features
    ]
    
    channel_data = channel_data.dropna(subset=clustering_features)
    
    return channel_data, clustering_features

def find_optimal_clusters(X_scaled, max_clusters=10):
    silhouette_scores = []
    inertias = []
    
    for k in range(2, max_clusters + 1):
        kmeans = KMeans(n_clusters=k, random_state=42)
        kmeans.fit(X_scaled)
        silhouette_scores.append(silhouette_score(X_scaled, kmeans.labels_))
        inertias.append(kmeans.inertia_)
    
    plt.figure(figsize=(12, 5))
    
    plt.subplot(1, 2, 1)
    plt.plot(range(2, max_clusters + 1), inertias, marker='o')
    plt.xlabel('Αριθμός clusters')
    plt.ylabel('Inertia')
    plt.title('Elbow Method')
    
    plt.subplot(1, 2, 2)
    plt.plot(range(2, max_clusters + 1), silhouette_scores, marker='o')
    plt.xlabel('Αριθμός clusters')
    plt.ylabel('Silhouette Score')
    plt.title('Silhouette Analysis')
    
    plt.tight_layout()
    plt.show()
    
    optimal_clusters = silhouette_scores.index(max(silhouette_scores)) + 2
    return optimal_clusters

def perform_clustering_analysis(data, features, n_clusters):
    X = data[features].copy()
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    kmeans = KMeans(n_clusters=n_clusters, random_state=42)
    data['cluster'] = kmeans.fit_predict(X_scaled)
    
    cluster_stats = data.groupby('cluster').agg({
        'channel_view_count': ['mean', 'count', 'min', 'max'],
        'channel_subscriber_count': ['mean', 'min', 'max'],
        'channel_video_count': ['mean', 'min', 'max']
    }).round(2)
    
    category_distribution = pd.crosstab(
        data['cluster'], 
        data['video_category_id'], 
        normalize='index'
    ) * 100
    
    return cluster_stats, category_distribution, kmeans.labels_

def visualize_clusters(data, features, labels):
    plt.figure(figsize=(15, 5))
    
    plt.subplot(1, 3, 1)
    plt.scatter(data[features[0]], data[features[1]], c=labels, cmap='viridis')
    plt.xlabel('Channel Views')
    plt.ylabel('Subscribers')
    plt.xscale('log')
    plt.yscale('log')
    plt.title('Views vs Subscribers')
    
    plt.subplot(1, 3, 2)
    plt.scatter(data[features[1]], data[features[2]], c=labels, cmap='viridis')
    plt.xlabel('Subscribers')
    plt.ylabel('Video Count')
    plt.xscale('log')
    plt.yscale('log')
    plt.title('Subscribers vs Videos')
    
    plt.subplot(1, 3, 3)
    plt.scatter(data[features[0]], data[features[2]], c=labels, cmap='viridis')
    plt.xlabel('Channel Views')
    plt.ylabel('Video Count')
    plt.xscale('log')
    plt.yscale('log')
    plt.title('Views vs Videos')
    
    plt.tight_layout()
    plt.show()

def main():
    file_path = 'cleaned_youtube_trending_videos_global.csv'
    data, features = load_and_prepare_data(file_path)
    
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(data[features])
    
    optimal_clusters = find_optimal_clusters(X_scaled)
    print(f"Optimal cluster number: {optimal_clusters}")
    
    cluster_stats, category_dist, labels = perform_clustering_analysis(
        data, features, optimal_clusters
    )
    
    print("\nCluster statistics:")
    print(cluster_stats)
    
    print("\nCategory distribution per cluster (%):")
    print(category_dist)
    
    visualize_clusters(data, features, labels)


if __name__ == "__main__":
    main()