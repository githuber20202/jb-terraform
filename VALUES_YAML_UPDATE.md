# עדכון נדרש ב-jb-gitops Repository

כדי שהאפליקציה תפסיק לרוץ ב-DEMO MODE, צריך לעדכן את הקובץ `values.yaml` בריפו jb-gitops.

## הקובץ לעדכן:
`jb-gitops/aws-resources-viewer/values.yaml`

## השינוי הנדרש:

### לפני (הגרסה הנוכחית):
```yaml
# Environment variables (optional - for AWS credentials)
env: []
  - name: AWS_ACCESS_KEY_ID
    value: "your-key"
  - name: AWS_SECRET_ACCESS_KEY
    value: "your-secret"
  - name: AWS_DEFAULT_REGION
    value: "us-east-1"
```

### אחרי (הגרסה המתוקנת - גישה פשוטה):
```yaml
# Environment variables - AWS credentials from Secret
# Using envFrom for simplicity (loads all keys from Secret)
env: []
```

ובקובץ `deployment.yaml` הוסף:
```yaml
        {{- if .Values.env }}
        env:
          {{- toYaml .Values.env | nindent 10 }}
        {{- end }}
        envFrom:
        - secretRef:
            name: aws-credentials
```

**או גישה חלופית** (אם לא רוצים לשנות deployment.yaml):
```yaml
# Environment variables - AWS credentials from Secret
env:
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: aws-credentials
        key: AWS_ACCESS_KEY_ID
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: aws-credentials
        key: AWS_SECRET_ACCESS_KEY
  - name: AWS_DEFAULT_REGION
    valueFrom:
      secretKeyRef:
        name: aws-credentials
        key: AWS_DEFAULT_REGION
```

## שלבי העדכון:

1. פתח את הריפו jb-gitops
2. ערוך את הקובץ `aws-resources-viewer/values.yaml`
3. החלף את החלק של `env:` בקוד המתוקן למעלה
4. שמור ועשה commit:
   ```bash
   git add aws-resources-viewer/values.yaml
   git commit -m "Configure AWS credentials via Kubernetes Secret"
   git push
   ```
5. ArgoCD יזהה את השינוי אוטומטית וי-sync את האפליקציה
6. ה-Pod יאתחל מחדש עם הקרדנציאלס מה-Secret

## אימות:

אחרי ה-sync, בדוק שהאפליקציה לא מציגה יותר "Demo Mode":
```bash
kubectl get pods
kubectl logs <pod-name>
```

גלוש ל-`http://<EC2_IP>:30080` - אמור להציג נתונים אמיתיים מ-AWS!
