# Componentes Reutilizáveis (Core Widgets)

Componentes visuais padrão de alta performance, desacoplados e escaláveis.

## Estrutura

```
lib/core/widgets/
├── buttons/
│   ├── app_elevated_button.dart    # Botão preenchido
│   └── app_outlined_button.dart    # Botão com contorno
├── inputs/
│   └── app_text_input.dart         # Campo de texto
├── google_sign_in_button.dart      # Botão Google especializado
├── app_screen_background.dart      # Fundo gradiente global
└── index.dart                      # Exports centralizados
```

## Componentes

### AppElevatedButton
Botão preenchido com estado de loading e ícone opcional.

```dart
AppElevatedButton(
  onPressed: () {},
  label: 'Entrar',
  isLoading: false,
  disabled: false,
)
```

### AppOutlinedButton
Botão com contorno para ações secundárias.

```dart
AppOutlinedButton(
  onPressed: () {},
  label: 'Cancelar',
)
```

### AppTextInput
Campo de texto com validação, ícones e múltiplas linhas.

```dart
AppTextInput(
  controller: controller,
  label: 'Email',
  hint: 'seu@email.com',
  keyboardType: TextInputType.emailAddress,
)
```

### GoogleSignInButton
Botão especializado para login com Google.

```dart
GoogleSignInButton(
  onPressed: () {},
  isLoading: false,
)
```

## Boas Práticas Aplicadas

- ✅ Componentes **sem estado** (StLessWidget)
- ✅ Props bem definidas e documentadas
- ✅ **const** keywords para otimização
- ✅ Desacoplamento completo (sem dependências cruzadas)
- ✅ Loading states integrados
- ✅ Organização por tipo (buttons/, inputs/)
- ✅ Exports centralizados em `index.dart`

## Performance

- Widgets const onde possível
- Sem rebuilds desnecessários
- Reutilização de tema global (AppTheme)
- Componentes funcionais e puros
