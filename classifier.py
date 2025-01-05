import pandas as pd
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import StratifiedKFold

df = pd.read_csv('cleaned_youtube_trending_videos_global.csv')

label_encoder = LabelEncoder()
df['video_category_id'] = label_encoder.fit_transform(df['video_category_id'])
df['video_dimension'] = label_encoder.fit_transform(df['video_dimension'])
df['video_definition'] = label_encoder.fit_transform(df['video_definition'])
df['channel_country'] = label_encoder.fit_transform(df['channel_country'])
df['channel_have_hidden_subscribers'] = label_encoder.fit_transform(df['channel_have_hidden_subscribers'].astype(str))

median_view_count = df['video_view_count'].median()
df['high_view_count'] = (df['video_view_count'] > median_view_count).astype(int)

features = ['video_category_id', 'video_duration', 'video_dimension', 'video_definition', 'channel_view_count', 
            'channel_subscriber_count', 'channel_video_count', 'channel_have_hidden_subscribers']

X = df[features]
y = df['high_view_count']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

rf_classifier = RandomForestClassifier(
    n_estimators=50,
    max_depth=None,
    min_samples_split=2,
)

cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
cv_scores = cross_val_score(rf_classifier, X_train, y_train, cv=cv, scoring='accuracy')

print(f"Cross-validation scores: {cv_scores}")
print(f"Mean cross-validation accuracy: {cv_scores.mean()}")

rf_classifier.fit(X_train, y_train)

y_pred = rf_classifier.predict(X_test)

print("Accuracy:", accuracy_score(y_test, y_pred))
y_train_pred = rf_classifier.predict(X_train)

print("Train Accuracy:", accuracy_score(y_train, y_train_pred))
print("Classification Report:\n", classification_report(y_test, y_pred))

feature_importances = pd.DataFrame(rf_classifier.feature_importances_,
                                   index=features,
                                   columns=['importance']).sort_values('importance', ascending=False)

print("Feature Importances:\n", feature_importances)