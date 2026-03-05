<div align="center">

# 🥧 App Empada

**Gestão de vendas para empreendedores autônomos**  
Integração com Mercado Pago · PIX · Relatórios · Controle de estoque

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Mercado Pago](https://img.shields.io/badge/Mercado%20Pago-PIX-009EE3?style=for-the-badge&logo=mercadopago&logoColor=white)](https://www.mercadopago.com.br)
[![SQLite](https://img.shields.io/badge/SQLite-Local_DB-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org)

</div>

---

## ✨ Funcionalidades

| Tela | O que faz |
|------|-----------|
| 📊 **Dashboard** | Cards com vendas do dia, estimativa máxima e gráfico de evolução |
| 📦 **Produtos** | Cadastro, edição e exclusão com alerta de estoque baixo |
| 🛒 **Nova Venda** | Grade de produtos, busca, carrinho animado e checkout rápido |
| 📱 **QR Code PIX** | Gera QR code via Mercado Pago e aguarda confirmação automaticamente |
| 📈 **Relatórios** | Gráfico de barras (por produto) e gráfico de linha (por dia — últimos 30 dias) |
| ⚙️ **Configurações** | Nome do negócio, CPF, token do Mercado Pago (armazenado com segurança) |

---

## 🚀 Como rodar

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- Android Studio / VS Code com extensão Flutter
- Conta no [Mercado Pago](https://www.mercadopago.com.br/developers) para obter o Access Token

### Instalação

```bash
# Clone o repositório
git clone <seu-repositorio>
cd app-empada

# Instale as dependências
flutter pub get

# Rode o app
flutter run
```

---

## 🔧 Configuração inicial

1. Abra o app e vá em **⚙️ Configurações**
2. Informe o **nome do seu negócio** e seu **CPF**
3. Cole o **Access Token** do Mercado Pago  
   _(Conta MP → Desenvolvimento → Credenciais → Produção)_
4. Salve — pronto! ✅

> **CNPJ opcional:** O campo CNPJ aparece na tela de configurações marcado como *"para o futuro"*. Se um dia você formalizar o negócio, basta preencher e o app já usa automaticamente.

---

## 💳 Fluxo de pagamento

```
Nova Venda
    │
    ▼
Seleciona produtos  →  Adiciona ao carrinho
    │
    ▼
Toca "Pagar"  →  App cria pagamento na API do Mercado Pago
    │
    ▼
QR Code PIX exibido  →  Cliente escaneia e paga
    │
    ▼
App detecta aprovação  →  Estoque decrementado automaticamente
    │
    ▼
✅ Aprovado / ❌ Recusado  →  Feedback visual imediato
```

---

## 🏗️ Arquitetura

```
lib/
├── core/
│   ├── constants.dart              # Constantes globais
│   └── database/
│       └── database_helper.dart   # SQLite singleton
├── models/                         # Entidades de dados
│   ├── product.dart
│   ├── sale.dart
│   ├── sale_item.dart
│   └── app_settings.dart
├── repositories/                   # Acesso ao banco local
│   ├── product_repository.dart
│   └── sale_repository.dart
├── services/                       # APIs externas e segurança
│   ├── mercado_pago_service.dart
│   └── settings_service.dart
├── providers/                      # Estado (Provider)
│   ├── product_provider.dart
│   ├── sale_provider.dart
│   ├── dashboard_provider.dart
│   └── settings_provider.dart
└── screens/                        # Telas
    ├── dashboard_screen.dart
    ├── products_screen.dart
    ├── product_form_screen.dart
    ├── new_sale_screen.dart
    ├── qr_code_screen.dart
    ├── reports_screen.dart
    └── settings_screen.dart
```

---

## 📦 Dependências principais

| Pacote | Uso |
|--------|-----|
| `provider` | Gerenciamento de estado |
| `sqflite` | Banco de dados local SQLite |
| `dio` | Requisições HTTP para a API do Mercado Pago |
| `fl_chart` | Gráficos de barras e linha |
| `qr_flutter` | Geração do QR code PIX |
| `flutter_secure_storage` | Armazenamento seguro do Access Token |
| `google_fonts` | Tipografia moderna (Outfit) |

---

## 🔐 Segurança

- O **Access Token** do Mercado Pago é armazenado com `flutter_secure_storage` (Keychain no iOS, Keystore no Android)
- Nenhuma credencial é exposta no código-fonte
- Entradas do usuário são validadas antes de qualquer operação

---

## 📊 Cálculo de Estimativa Diária

```
Estimativa Máxima = Σ (preço × quantidade em estoque) de todos os produtos
Percentual atingido = (Total vendido hoje / Estimativa Máxima) × 100
```

---

## 📝 Licença

Projeto desenvolvido para uso pessoal. Sinta-se livre para adaptar às suas necessidades.

---

<div align="center">

Feito com ❤️ e muito Flutter para vender muitas empadas 🥧

</div>