# Demonstrar a aplicação original completa

O roteiro de CRUD de Cloud testa quatro tabelas sem gerar histórico que impediria a exclusão. Use outro conjunto de propriedades/cultivos para os módulos abaixo; os dados históricos são preservados pela regra de negócio e áreas com histórico devem ser arquivadas, não removidas.

1. Cadastre e autentique um produtor. Crie propriedade, área e sensor pelo Swagger da URL em nuvem.
2. Mostre o perfil agronômico: GET/PUT `/api/crop-areas/{id}/agronomic-profile`. O exemplo de corpo está em requests/profile.json. Mostre a revisão persistida.
3. Registre atividade de irrigação. Demonstre filtros e a consulta da atividade.
4. Envie leitura por POST `/api/sensor-readings`, com sensorId real e measuredAt atual. Os exemplos estão no Swagger e README-APLICACAO.md; use dados demonstrativos identificados, sem afirmar medição de campo.
5. Solicite POST `/api/crop-areas/{id}/risk-jobs`, acompanhe o 202 e depois GET `/api/risk-jobs/{jobId}`. Explique outbox/RabbitMQ e o cálculo determinístico. Mostre status e resultado após o consumidor processar.
6. Mostre GET `/api/alerts`, `/api/dashboard` e `/api/sensors/{sensorId}/health`. Se houver alerta, use as transições de reconhecimento e resolução do próprio sistema.
7. Se GOOGLE_API_KEY e APP_AI_ENABLED estiverem configurados, solicite POST `/api/risk-jobs/{jobId}/guidance` e mostre a orientação real com fontes. Essa chamada não muda o risco determinístico. Em caso de indisponibilidade, apresente o estado de erro retornado pela integração.
8. Demonstre arquivamento de cultivo com histórico pela rota PATCH `/api/crop-areas/{id}/archive`. Para o ciclo CRUD de Cloud, use os dados novos e descartáveis do smoke-test, que não possuem perfil/leituras/jobs.

Dispositivos/técnicos, simulação identificada, orientação pós-irrigação e análise legada têm contratos preservados em docs/README-APLICACAO.md, docs/IMPLEMENTATION_STATUS.md e Swagger. Se forem parte do recorte apresentado pelo grupo nas outras disciplinas, configure e demonstre os respectivos fluxos; não trate o roteiro de CRUD como substituto desses módulos.

Para verificar as tabelas históricas no banco, use SELECT sem campos sensíveis: agronomic_profiles, sensor_readings, outbox_events e risk_jobs. Preserve os registros de auditoria e as regras de integridade. scripts/script-bd.sql documenta os objetos, enquanto Flyway controla as versões aplicadas.
