Petite explication rapide sur le contenu du dossier :

- config_export.yaml définit une configmap qui contient quelques variables d'environnement.

- secret_config.yaml définit 2 secrets qui contiennent des valeurs randoms.

- config-dep.yaml définit un déploiement busybox qui appelle la configmap et les secrets, en echo un de chaque puis part sleep pendant 1000.
