# Padrões - Spring Boot API

## 🔍 ANTES DE INICIAR

**IMPORTANTE**: Antes de começar a implementar ou modificar código neste projeto:

1. **Analise a estrutura de pastas**: Use ferramentas de busca (Glob, Grep) para mapear a organização atual do projeto
2. **Identifique padrões existentes**: Verifique como controllers, services, repositories e entities estão organizados
3. **Leia arquivos de configuração**: `application.properties`/`application.yml`, `pom.xml`, migrations (Flyway/Liquibase)
4. **Entenda convenções do projeto**: Nomenclatura, estrutura de pacotes, tratamento de erros já implementados
5. **Verifique dependências**: Bibliotecas adicionais (Lombok, MapStruct, Swagger, etc) que podem estar em uso

**Só inicie a implementação após entender a organização e padrões do projeto existente.**

---

## Stack
- Java 17+
- Spring Boot 3.x
- Maven
- JPA/Hibernate
- MySQL/MariaDB

## Arquitetura
- Clean Architecture
- Controller → Service → Repository → Entity
- DTOs com record classes

## Estrutura de Pacotes
```
com.empresa.projeto
├── controller
├── service
├── repository
├── entity
├── dto
└── exception
```

## Convenções de Código
- Services: `@Service`, métodos transacionais
- Controllers: `@RestController`, endpoints no plural
- Repositories: `extends JpaRepository<Entity, Long>`
- DTOs: usar `record` para imutabilidade
- Exceções: `CustomException extends RuntimeException`
- Logs: `@Slf4j` do Lombok

## Banco de Dados
- Naming: snake_case nas tabelas
- Migrations: Flyway
- Relacionamentos: sempre com @JoinColumn

## REST API
- Endpoints: `/api/v1/resources` (plural)
- POST: retorna 201 Created
- PUT: retorna 200 OK
- DELETE: retorna 204 No Content
- GET: retorna 200 OK com lista ou objeto

## Validações
- Bean Validation: `@Valid` nos controllers
- Validações customizadas em services

## Tratamento de Erros
- GlobalExceptionHandler com `@ControllerAdvice`
- Retornar objetos padronizados de erro

## Qualidade de Código

### Clean Code

- **Nomes descritivos**: variáveis, métodos e classes devem ser autoexplicativos
- **Métodos pequenos**: cada método deve fazer uma única coisa
- **Sem código duplicado**: extrair para métodos ou classes utilitárias
- **Responsabilidade única**: cada classe com propósito claro
- **Código limpo e legível**: evitar complexidade desnecessária

### Design Patterns

- Aplicar padrões de projeto quando apropriado (Strategy, Factory, Builder, Template Method, etc)
- Services são o lugar ideal para aplicação de patterns
- Não force patterns onde não fazem sentido

### Comentários

- **Código deve ser autoexplicativo** - comentários geralmente indicam código confuso
- Comentar apenas quando absolutamente necessário (lógica complexa inevitável, workarounds, TODOs)
- Preferir refatoração a comentários explicativos
- JavaDoc em APIs públicas e métodos complexos

### Idioma

- **Português por padrão** em todo o código
- Nomes de classes, métodos, variáveis em português
- Comentários e documentação em português
- Mensagens de erro e logs em português

---

## Entities Avançado

### Hierarquia de Superclasses com @MappedSuperclass

Crie classes base para reutilizar campos comuns (auditing, soft delete, etc):

```java
@MappedSuperclass
@Getter
@Setter
public abstract class Entidade {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    protected Long id;

    @CreationTimestamp
    @Temporal(TemporalType.TIMESTAMP)
    private Date criadoEm;

    private Long criadoPor;

    @UpdateTimestamp
    @Temporal(TemporalType.TIMESTAMP)
    private Date modificadoEm;

    private Long modificadoPor;

    @Convert(converter = BooleanToStringConverter.class)
    private Boolean excluido = Boolean.FALSE;
}

@MappedSuperclass
public abstract class EntidadeNome extends Entidade {
    @NotEmpty(message = "O campo nome é obrigatório")
    private String nome;
}
```

**Outras superclasses úteis:**
- `EntidadeAtivo` (adiciona campo `ativo`)
- `EntidadeOrdem` (adiciona campo `ordem` para ordenação)
- `EntidadeNomeAtivo`, `EntidadeNomeAtivoOrdem`, etc

### Soft Delete com Hibernate

Use `@SQLDelete` + `@SQLRestriction` para exclusão lógica:

```java
@Entity
@Table(name = "CLIENTE")
@SQLDelete(sql = "UPDATE CLIENTE SET excluido = 'T' WHERE id = ?",
           check = ResultCheckStyle.COUNT)
@SQLRestriction("excluido <> 'T'")
public class Cliente extends Entidade {
    // campos da entidade
}
```

**Benefícios:**
- Transparente: repositories não precisam filtrar `excluido = false`
- `repository.delete(cliente)` executa UPDATE ao invés de DELETE
- Queries automáticas já filtram registros excluídos

### BooleanToStringConverter

Para bancos que armazenam booleanos como "T"/"F":

```java
@Converter(autoApply = true)
public class BooleanToStringConverter implements AttributeConverter<Boolean, String> {

    @Override
    public String convertToDatabaseColumn(Boolean attribute) {
        return (attribute != null && attribute) ? "T" : "F";
    }

    @Override
    public Boolean convertToEntityAttribute(String dbData) {
        return "T".equalsIgnoreCase(dbData);
    }
}
```

**Uso na entity:**
```java
@Convert(converter = BooleanToStringConverter.class)
private Boolean ativo = Boolean.TRUE;
```

### Auditing com Hibernate

Use `@CreationTimestamp` e `@UpdateTimestamp` para auditing automático:

```java
@CreationTimestamp
@Temporal(TemporalType.TIMESTAMP)
private Date criadoEm;

@UpdateTimestamp
@Temporal(TemporalType.TIMESTAMP)
private Date modificadoEm;
```

**Alternativa com Spring Data JPA:**
```java
@EntityListeners(AuditingEntityListener.class)
public class Entidade {
    @CreatedDate
    private LocalDateTime criadoEm;

    @LastModifiedDate
    private LocalDateTime modificadoEm;

    @CreatedBy
    private Long criadoPor;

    @LastModifiedBy
    private Long modificadoPor;
}
```

### Lazy Loading Forçado

Método para inicializar coleções lazy quando necessário:

```java
public void inicializarListas() {
    if (this.preferencias != null) {
        this.preferencias.size(); // Força fetch
    }
    if (this.enderecos != null) {
        this.enderecos.size();
    }
}
```

### Padrões nas Entities

```java
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "CLIENTE")
@SQLDelete(sql = "UPDATE CLIENTE SET excluido = 'T' WHERE id = ?")
@SQLRestriction("excluido <> 'T'")
@Builder
@Getter
@Setter
public class Cliente extends EntidadeNome {

    @OneToOne
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @NotEmpty(message = "Campo celular é obrigatório!")
    @Column(nullable = false)
    private String celular;

    @NotNull(message = "Campo gênero é obrigatório!")
    @Enumerated(EnumType.STRING)
    private TipoGenero tipoGenero;

    @ManyToMany
    @JoinTable(
        name = "CLIENTE_PREFERENCIAS",
        joinColumns = @JoinColumn(name = "cliente_id"),
        inverseJoinColumns = @JoinColumn(name = "categoria_id")
    )
    @JsonIgnore  // Evita serialização circular
    private List<Categoria> preferencias;

    // Métodos de negócio
    public boolean temPreferencias() {
        return preferencias != null && !preferencias.isEmpty();
    }
}
```

**Boas práticas:**
- ✅ Usar `@Getter` e `@Setter` separadamente (não `@Data`)
- ✅ `@Builder` para construção fluente
- ✅ `@JsonIgnore` em relacionamentos bidirecionais
- ✅ Validações Bean Validation nas entities
- ✅ Métodos de negócio na entity quando fazem sentido

---

## Repositories Avançado

### Repository Base Customizado

Crie interface base com métodos úteis para todos os repositories:

```java
@NoRepositoryBean
public interface BaseRepository<T, ID> extends JpaRepository<T, ID> {

    /**
     * Busca por ID e lança exceção se não encontrado
     */
    default T get(ID id) {
        return findById(id).orElseThrow(
            () -> new RecursoNaoEncontradoException(
                domainClass().getSimpleName() + " não encontrado: " + id
            )
        );
    }

    /**
     * Retorna a classe de domínio do repository
     */
    default Class<?> domainClass() {
        return GenericTypeResolver.resolveTypeArgument(
            getClass(), BaseRepository.class
        );
    }
}
```

**Uso:**
```java
public interface ClienteRepository extends BaseRepository<Cliente, Long> {
    // métodos customizados
}

// No service
Cliente cliente = clienteRepository.get(id); // Lança exceção se não existir
```

### Queries JPQL com Parâmetros Opcionais

Padrão para filtros opcionais em queries:

```java
@Query("""
    SELECT e FROM Evento e
    LEFT JOIN e.categorias c
    LEFT JOIN e.endereco end
    WHERE (:nome IS NULL OR :nome = '' OR e.nome LIKE %:nome%)
    AND (:categoria IS NULL OR c.id IN :categoria)
    AND (:cidade IS NULL OR end.cidade LIKE %:cidade%)
    AND (:ativo IS NOT TRUE OR e.ativo = true)
""")
Page<Evento> findByFiltro(
    @Param("nome") String nome,
    @Param("categoria") List<Long> categoria,
    @Param("cidade") String cidade,
    @Param("ativo") Boolean ativo,
    Pageable pageable
);
```

**Padrão:**
- `:parametro IS NULL` → permite passar `null` para ignorar o filtro
- `:parametro = ''` → permite passar string vazia
- `:ativo IS NOT TRUE` → só filtra se `true`, ignora se `false` ou `null`

### Text Blocks para Queries Complexas (Java 15+)

Use `"""` para queries de múltiplas linhas:

```java
@Query("""
    SELECT DISTINCT e FROM Evento e
    LEFT JOIN e.datas de
    WHERE (:dataInicio IS NULL AND :dataFim IS NULL)
       OR (:dataInicio IS NOT NULL AND :dataFim IS NOT NULL
           AND de.dataInicio BETWEEN :dataInicio AND :dataFim)
       OR (:dataInicio IS NOT NULL AND :dataFim IS NULL
           AND de.dataInicio >= :dataInicio)
       OR (:dataInicio IS NULL AND :dataFim IS NOT NULL
           AND de.dataInicio <= :dataFim)
""")
Page<Evento> findByPeriodo(
    @Param("dataInicio") LocalDate dataInicio,
    @Param("dataFim") LocalDate dataFim,
    Pageable pageable
);
```

### Interface Projections

Para queries que retornam apenas campos específicos:

```java
public interface CategoriaProjection {
    Long getId();
    String getNome();
    String getSlug();
}

// No repository
@Query("SELECT c.id as id, c.nome as nome, c.slug as slug FROM Categoria c")
List<CategoriaProjection> findAllProjection();
```

**Benefícios:**
- Performance: busca apenas campos necessários
- Type-safe: interface garante tipos corretos
- Menos dados trafegados

### Padrões de Repository

```java
public interface EventoRepository extends BaseRepository<Evento, Long> {

    // Query methods simples
    List<Evento> findByAtivo(Boolean ativo);
    boolean existsBySlug(String slug);

    // JPQL complexa
    @Query("""
        SELECT DISTINCT e FROM Evento e
        LEFT JOIN e.categorias c
        WHERE :categoria IS NULL OR c IN :categoria
    """)
    List<Evento> findByCategorias(@Param("categoria") List<Categoria> categoria);

    // Native SQL (quando JPQL não é suficiente)
    @Query(value = "SELECT * FROM EVENTO WHERE ST_Distance_Sphere(" +
           "point(longitude, latitude), point(:lng, :lat)) <= :raio",
           nativeQuery = true)
    List<Evento> findByGeolocalizacao(
        @Param("lat") Double latitude,
        @Param("lng") Double longitude,
        @Param("raio") Double raio
    );

    // Projections
    @Query("SELECT e.id as id, e.nome as nome FROM Evento e")
    List<EventoProjection> findAllSimplificado();
}
```

---

## Controllers REST Avançado

### Interface + Implementation (Documentação Swagger)

Separe documentação (interface) de implementação (controller):

**EventoAPI.java (Interface):**
```java
public interface EventoAPI {

    @Operation(summary = "Criar um evento")
    @ApiResponses({
        @ApiResponse(
            responseCode = "201",
            description = "Evento criado com sucesso",
            content = @Content(
                mediaType = APPLICATION_JSON_VALUE,
                schema = @Schema(implementation = EventoResponse.class)
            )
        ),
        @ApiResponse(
            responseCode = "400",
            description = "Requisição inválida",
            content = @Content(
                mediaType = APPLICATION_JSON_VALUE,
                schema = @Schema(implementation = ErroResponse.class)
            )
        )
    })
    @PostMapping(value = "/v1", consumes = APPLICATION_JSON_VALUE)
    EventoResponse criarEvento(
        @RequestBody
        @Parameter(description = "Dados do evento")
        @Valid EventoRequest request
    );
}
```

**EventoController.java (Implementation):**
```java
@Tag(name = "Gerenciamento de Eventos")
@RestController
@RequestMapping("/api/eventos")
@RequiredArgsConstructor
public class EventoController implements EventoAPI {

    private final EventoService eventoService;

    @Override
    @PostMapping(value = "/v1", produces = APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasRole('ADMINISTRADOR')")
    public EventoResponse criarEvento(@Valid @RequestBody EventoRequest request) {
        return eventoService.criarEvento(request);
    }
}
```

**Benefícios:**
- Documentação Swagger separada da lógica
- Interface serve como contrato
- Controller mais limpo

### Multipart/Form-Data (Upload de Arquivos)

Para endpoints que recebem JSON + arquivo:

```java
@PostMapping(value = "/v1",
             consumes = MULTIPART_FORM_DATA_VALUE,
             produces = APPLICATION_JSON_VALUE)
@ResponseStatus(HttpStatus.CREATED)
public ClienteResponse criarCliente(
    @RequestPart("dados")
    @Parameter(
        description = "Dados do cliente em JSON",
        content = @Content(
            mediaType = APPLICATION_JSON_VALUE,
            schema = @Schema(implementation = ClienteRequest.class)
        )
    )
    @Valid ClienteRequest request,

    @RequestPart(value = "avatar", required = false)
    @Parameter(description = "Avatar do cliente")
    MultipartFile avatar
) {
    return clienteService.criarCliente(request, avatar);
}
```

**Request no cliente (JavaScript/Postman):**
```javascript
const formData = new FormData();
formData.append('dados', new Blob([JSON.stringify(clienteData)], {
    type: 'application/json'
}));
formData.append('avatar', fileInput.files[0]);

fetch('/api/clientes/v1', {
    method: 'POST',
    body: formData
});
```

### Paginação Padronizada

```java
@GetMapping(value = "/v1", produces = APPLICATION_JSON_VALUE)
public PageResponse<EventoResponse> buscarEventos(
    @RequestParam(defaultValue = "0") Integer pageNumber,
    @RequestParam(defaultValue = "10") Integer pageSize,
    @RequestParam(defaultValue = "id") String sortBy,
    @RequestParam(defaultValue = "ASC") String sortDirection,
    @RequestParam(required = false) String nome,
    @RequestParam(required = false) Boolean ativo
) {
    return eventoService.buscarEventos(
        pageNumber, pageSize, sortBy, sortDirection, nome, ativo
    );
}
```

**Padrões:**
- `defaultValue` em parâmetros de paginação
- `required = false` em filtros opcionais
- Retornar `PageResponse<T>` (não `Page<T>` diretamente)

### Versionamento de API

```java
@RequestMapping("/api/eventos")
public class EventoController {

    @PostMapping("/v1")
    public EventoResponse criarEventoV1(@RequestBody EventoRequestV1 request) { }

    @PostMapping("/v2")
    public EventoResponse criarEventoV2(@RequestBody EventoRequestV2 request) { }
}
```

**Alternativas:**
- Path: `/api/v1/eventos`, `/api/v2/eventos`
- Header: `Accept: application/vnd.api.v1+json`
- Query param: `/api/eventos?version=1`

---

## DTOs e Conversão

### DTOs com Records (Java 14+)

**Request DTOs:**
```java
public record ClienteRequest(

    @Schema(description = "Nome completo", example = "João Silva")
    @NotBlank(message = "O nome é obrigatório")
    String nome,

    @Schema(description = "E-mail", example = "joao@email.com")
    @Email(message = "E-mail inválido")
    String email,

    @Size(min = 8, max = 100, message = "Senha deve ter entre 8 e 100 caracteres")
    String senha,

    @Schema(description = "CPF", example = "123.456.789-00")
    String cpf,

    @NotBlank(message = "Celular é obrigatório")
    String celular,

    @Schema(description = "Gênero: MASCULINO, FEMININO, OUTROS, NAO_INFORMAR")
    String tipoGenero,

    String dataNascimento,
    Boolean ativo
) {
    // Records são imutáveis por padrão
    // Getters gerados automaticamente: nome(), email(), etc
}
```

**Response DTOs:**
```java
public record ClienteResponse(
    Long id,
    String nome,
    String email,
    String tipoUsuario,
    String tipoUsuarioExibicao,  // Enum com valor amigável
    String cpf,
    String celular,
    boolean ativo,
    String dataNascimento,
    String avatarUrl,
    Integer qtdSeguidores,  // Campo calculado
    Integer qtdEventosCurtidos,  // Campo calculado
    String criadoEm
) {
}
```

### Adapter Pattern para Conversão

Use classes `*Adapter.java` com `@UtilityClass` do Lombok:

```java
@UtilityClass
public class ClienteAdapter {

    /**
     * Converte Request DTO → Entity
     */
    public static Cliente toEntity(ClienteRequest request, Usuario usuario) {
        Cliente cliente = Cliente.builder()
            .usuario(usuario)
            .celular(FormatterUtils.removerMascara(request.celular()))
            .cpf(request.cpf())
            .tipoGenero(request.tipoGenero() != null
                ? TipoGenero.valueOf(request.tipoGenero())
                : null)
            .dataNascimento(DateUtils.stringToLocalDate(request.dataNascimento()))
            .build();

        cliente.setNome(request.nome());
        cliente.setAtivo(request.ativo());
        return cliente;
    }

    /**
     * Converte Entity → Response DTO (versão simples)
     */
    public static ClienteResponse toResponse(Cliente cliente, String baseUrl) {
        if (cliente == null) return null;

        return new ClienteResponse(
            cliente.getId(),
            cliente.getNome(),
            cliente.getUsuario().getEmail(),
            cliente.getUsuario().getTipo().toString(),
            cliente.getUsuario().getTipo().getExibicao(),
            cliente.getCpf(),
            cliente.getCelular(),
            cliente.getAtivo(),
            DateUtils.localDateToString(cliente.getDataNascimento()),
            baseUrl + "/arquivos/" + cliente.getUsuario().getAvatar(),
            null,  // qtdSeguidores (calculado posteriormente se necessário)
            null,  // qtdEventosCurtidos
            DateUtils.dateToString(cliente.getCriadoEm())
        );
    }

    /**
     * Converte Entity → Response DTO (versão completa com campos calculados)
     */
    public static ClienteResponse toResponse(
        Cliente cliente,
        String baseUrl,
        Integer qtdSeguidores,
        Integer qtdEventosCurtidos
    ) {
        ClienteResponse response = toResponse(cliente, baseUrl);
        return new ClienteResponse(
            response.id(), response.nome(), response.email(),
            response.tipoUsuario(), response.tipoUsuarioExibicao(),
            response.cpf(), response.celular(), response.ativo(),
            response.dataNascimento(), response.avatarUrl(),
            qtdSeguidores,  // Agora preenchido
            qtdEventosCurtidos,
            response.criadoEm()
        );
    }

    /**
     * Cria entity apenas com ID (para relacionamentos)
     */
    public static Cliente toEntityById(Long id) {
        Cliente cliente = new Cliente();
        cliente.setId(id);
        return cliente;
    }
}
```

**Uso no Service:**
```java
@Service
@RequiredArgsConstructor
public class ClienteService {

    private final ClienteRepository clienteRepository;

    public ClienteResponse criarCliente(ClienteRequest request) {
        // Request → Entity
        Cliente cliente = ClienteAdapter.toEntity(request, usuario);
        clienteRepository.save(cliente);

        // Entity → Response
        return ClienteAdapter.toResponse(cliente, baseUrl);
    }
}
```

### PageResponse Wrapper

Wrapper customizado para paginação (não expõe `Page<T>` do Spring):

```java
@Builder
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PageResponse<T> {
    private List<T> content;
    private int currentPage;
    private int pageSize;
    private long totalElements;
    private int totalPages;
}
```

**Uso no Service:**
```java
public PageResponse<ClienteResponse> buscarClientes(
    Integer pageNumber, Integer pageSize, String sortBy, String sortDirection
) {
    Pageable pageable = PaginacaoUtils.criarPageable(
        pageNumber, pageSize, sortBy, sortDirection
    );

    Page<Cliente> page = clienteRepository.findAll(pageable);

    // Converte Page<Entity> → Page<Response>
    Page<ClienteResponse> responsePage = page.map(
        cliente -> ClienteAdapter.toResponse(cliente, baseUrl)
    );

    // Converte Page<Response> → PageResponse<Response>
    return PageResponse.<ClienteResponse>builder()
        .content(responsePage.getContent())
        .currentPage(responsePage.getNumber())
        .pageSize(responsePage.getSize())
        .totalElements(responsePage.getTotalElements())
        .totalPages(responsePage.getTotalPages())
        .build();
}
```

### PaginacaoUtils

Classe utilitária para criar `Pageable` com valores default:

```java
@UtilityClass
public class PaginacaoUtils {

    public static Pageable criarPageable(
        Integer pageNumber,
        Integer pageSize,
        String sortBy,
        String sortDirection
    ) {
        if (pageNumber == null) pageNumber = 0;
        if (pageSize == null) pageSize = 10;
        if (sortBy == null || sortBy.isBlank()) sortBy = "id";
        if (sortDirection == null || sortDirection.isBlank()) sortDirection = "ASC";

        Sort sort = "DESC".equalsIgnoreCase(sortDirection)
            ? Sort.by(sortBy).descending()
            : Sort.by(sortBy).ascending();

        return PageRequest.of(pageNumber, pageSize, sort);
    }
}
```

---

## Security Avançado

### JWT com Subject Criptografado

Para maior segurança, criptografe o ID do usuário antes de colocar no token:

```java
@Service
@RequiredArgsConstructor
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.secret.crypto}")
    private String secretCrypto;

    private static final long EXPIRACAO_ACCESS_TOKEN = 3600000; // 1 hora
    private static final long EXPIRACAO_REFRESH_TOKEN = 86400000; // 24 horas

    private Key getChaveSecreta() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String gerarToken(Usuario usuario) {
        // Criptografa o ID antes de colocar no subject
        String idCriptografado = CryptoUtils.criptografar(
            usuario.getId().toString(),
            secretCrypto
        );

        return Jwts.builder()
            .setSubject(idCriptografado)
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + EXPIRACAO_ACCESS_TOKEN))
            .signWith(getChaveSecreta())
            .compact();
    }

    public boolean validarToken(String token) {
        try {
            Jwts.parserBuilder()
                .setSigningKey(getChaveSecreta())
                .build()
                .parseClaimsJws(token);
            return true;
        } catch (ExpiredJwtException e) {
            throw new TokenExpiradoException("Token expirado");
        } catch (Exception e) {
            throw new TokenInvalidoException("Token inválido");
        }
    }

    public Long extrairUsuarioId(String token) {
        String idCriptografado = Jwts.parserBuilder()
            .setSigningKey(getChaveSecreta())
            .build()
            .parseClaimsJws(token)
            .getBody()
            .getSubject();

        // Descriptografa para obter o ID real
        String id = CryptoUtils.descriptografar(idCriptografado, secretCrypto);
        return Long.parseLong(id);
    }
}
```

### Refresh Token Persistido

Armazene refresh tokens no banco para controle de sessões:

```java
@Entity
@Table(name = "REFRESH_TOKEN")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RefreshToken {

    @Id
    private String token;

    @Column(nullable = false)
    private String chave;  // ID criptografado

    @Column(nullable = false)
    private Long usuarioId;

    @Column(nullable = false)
    private Instant expiraEm;
}
```

**Service:**
```java
public RefreshToken gerarRefreshToken(Usuario usuario) {
    String idCriptografado = CryptoUtils.criptografar(
        usuario.getId().toString(), secretCrypto
    );

    String token = Jwts.builder()
        .setSubject(idCriptografado)
        .setIssuedAt(new Date())
        .setExpiration(new Date(System.currentTimeMillis() + EXPIRACAO_REFRESH_TOKEN))
        .signWith(getChaveSecreta())
        .compact();

    RefreshToken refreshToken = new RefreshToken(
        token,
        idCriptografado,
        usuario.getId(),
        Instant.now().plusMillis(EXPIRACAO_REFRESH_TOKEN)
    );

    return refreshTokenRepository.save(refreshToken);
}

public String refreshAccessToken(String refreshToken) {
    RefreshToken token = refreshTokenRepository.findById(refreshToken)
        .orElseThrow(() -> new TokenInvalidoException("Refresh token inválido"));

    if (token.getExpiraEm().isBefore(Instant.now())) {
        refreshTokenRepository.delete(token);
        throw new TokenExpiradoException("Refresh token expirado");
    }

    Usuario usuario = usuarioRepository.findById(token.getUsuarioId())
        .orElseThrow(() -> new RecursoNaoEncontradoException("Usuário não encontrado"));

    return gerarToken(usuario);
}
```

### LogadoUtils + Null Object Pattern

Classe utilitária para obter usuário logado:

```java
@UtilityClass
public class LogadoUtils {

    public static Usuario getUsuarioLogado() {
        Authentication authentication = SecurityContextHolder
            .getContext()
            .getAuthentication();

        if (authentication != null
            && authentication.getPrincipal() instanceof UsuarioSecurityConfig) {
            UsuarioSecurityConfig userDetails =
                (UsuarioSecurityConfig) authentication.getPrincipal();
            return userDetails.getUsuario();
        }

        return new UsuarioNaoLogado();  // Null Object Pattern
    }

    public static Cliente getClienteLogado() {
        Usuario usuario = getUsuarioLogado();

        if (usuario instanceof UsuarioNaoLogado) {
            throw new BusinessException("Usuário não autenticado");
        }

        if (usuario.getCliente() == null) {
            throw new BusinessException("Usuário não é um cliente");
        }

        return usuario.getCliente();
    }
}
```

**Null Object:**
```java
public class UsuarioNaoLogado extends Usuario {
    // Representa ausência de usuário logado
    // Evita null checks em todo lugar
}
```

**Uso no Service:**
```java
public EventoResponse curtirEvento(Long eventoId) {
    Usuario usuario = LogadoUtils.getUsuarioLogado();

    if (usuario instanceof UsuarioNaoLogado) {
        throw new BusinessException("Você precisa estar logado");
    }

    // continua lógica...
}
```

### GlobalExceptionHandler Completo

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(RecursoNaoEncontradoException.class)
    public ResponseEntity<ErroResponse> handleRecursoNaoEncontrado(
        RecursoNaoEncontradoException ex,
        WebRequest request
    ) {
        ErroResponse erro = ErroResponse.builder()
            .status(HttpStatus.NOT_FOUND.value())
            .mensagem(ex.getMessage())
            .dateTime(LocalDateTime.now())
            .path(request.getDescription(false).replace("uri=", ""))
            .build();

        log.error("Recurso não encontrado: {}", ex.getMessage());
        return new ResponseEntity<>(erro, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErroResponse> handleBusinessException(
        BusinessException ex,
        WebRequest request
    ) {
        ErroResponse erro = ErroResponse.builder()
            .status(HttpStatus.BAD_REQUEST.value())
            .mensagem(ex.getMessage())
            .dateTime(LocalDateTime.now())
            .path(request.getDescription(false).replace("uri=", ""))
            .build();

        log.warn("Erro de negócio: {}", ex.getMessage());
        return new ResponseEntity<>(erro, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErroResponse> handleValidationException(
        MethodArgumentNotValidException ex,
        WebRequest request
    ) {
        // Agrupa erros por campo
        Map<String, List<String>> fieldErrorsMap = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .collect(Collectors.groupingBy(
                FieldError::getField,
                Collectors.mapping(
                    FieldError::getDefaultMessage,
                    Collectors.toList()
                )
            ));

        List<CampoErroResponse> fieldErrors = fieldErrorsMap.entrySet()
            .stream()
            .map(entry -> CampoErroResponse.builder()
                .campo(entry.getKey())
                .erros(entry.getValue())
                .build()
            )
            .toList();

        ErroResponse erro = ErroResponse.builder()
            .status(HttpStatus.BAD_REQUEST.value())
            .mensagem("Erro na validação de campos")
            .camposErroResponse(fieldErrors)
            .dateTime(LocalDateTime.now())
            .path(request.getDescription(false).replace("uri=", ""))
            .build();

        log.warn("Erro de validação: {}", fieldErrors);
        return new ResponseEntity<>(erro, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(AuthorizationDeniedException.class)
    public ResponseEntity<ErroResponse> handleAuthorizationDenied(
        AuthorizationDeniedException ex,
        WebRequest request
    ) {
        ErroResponse erro = ErroResponse.builder()
            .status(HttpStatus.FORBIDDEN.value())
            .mensagem("Acesso negado")
            .dateTime(LocalDateTime.now())
            .path(request.getDescription(false).replace("uri=", ""))
            .build();

        log.warn("Acesso negado: {}", ex.getMessage());
        return new ResponseEntity<>(erro, HttpStatus.FORBIDDEN);
    }

    @ExceptionHandler(TokenExpiradoException.class)
    public ResponseEntity<Map<String, String>> handleTokenExpirado(
        TokenExpiradoException ex
    ) {
        Map<String, String> response = new HashMap<>();
        response.put("message", ex.getMessage());
        response.put("code", "token.expired");

        log.warn("Token expirado: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErroResponse> handleGlobalException(
        Exception ex,
        WebRequest request
    ) {
        ErroResponse erro = ErroResponse.builder()
            .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
            .mensagem("Erro interno do servidor")
            .dateTime(LocalDateTime.now())
            .path(request.getDescription(false).replace("uri=", ""))
            .build();

        log.error("Erro não tratado: ", ex);
        return new ResponseEntity<>(erro, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
```

**ErroResponse:**
```java
@Builder
@Getter
public class ErroResponse {
    private int status;
    private String mensagem;
    private LocalDateTime dateTime;
    private String path;
    private List<CampoErroResponse> camposErroResponse;
}

@Builder
@Getter
public class CampoErroResponse {
    private String campo;
    private List<String> erros;
}
```

---

## Design Patterns

### Strategy Pattern com @ConditionalOnProperty

Para implementações intercambiáveis baseadas em configuração:

```java
// Interface
public interface StorageService {
    String uploadFile(MultipartFile file, String path);
    Optional<InputStream> downloadFile(String path);
    void deleteFile(String path);
}

// Implementação S3
@Service
@ConditionalOnProperty(name = "storage.type", havingValue = "s3")
@RequiredArgsConstructor
public class S3StorageService implements StorageService {

    private final AmazonS3 amazonS3;

    @Value("${s3.bucket.name}")
    private String bucketName;

    @Override
    public String uploadFile(MultipartFile file, String path) {
        try {
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(file.getSize());
            metadata.setContentType(file.getContentType());

            amazonS3.putObject(bucketName, path, file.getInputStream(), metadata);
            return amazonS3.getUrl(bucketName, path).toString();
        } catch (Exception e) {
            throw new BusinessException("Erro ao fazer upload: " + e.getMessage());
        }
    }

    // outros métodos...
}

// Implementação Local
@Service
@ConditionalOnProperty(name = "storage.type", havingValue = "local")
public class LocalStorageService implements StorageService {

    @Value("${storage.local.path}")
    private String localPath;

    @Override
    public String uploadFile(MultipartFile file, String path) {
        try {
            Path filePath = Paths.get(localPath, path);
            Files.createDirectories(filePath.getParent());
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            return filePath.toString();
        } catch (Exception e) {
            throw new BusinessException("Erro ao salvar arquivo: " + e.getMessage());
        }
    }

    // outros métodos...
}
```

**application.properties:**
```properties
# Alterna entre implementações
storage.type=s3  # ou "local"

# S3
s3.bucket.name=meu-bucket

# Local
storage.local.path=/var/uploads
```

**Uso no Service:**
```java
@Service
@RequiredArgsConstructor
public class ArquivoService {

    private final StorageService storageService;  // Spring injeta a implementação correta

    public String uploadAvatar(MultipartFile file, Long usuarioId) {
        String path = "avatars/" + usuarioId + "/" + file.getOriginalFilename();
        return storageService.uploadFile(file, path);
    }
}
```

### Null Object Pattern

Para evitar null checks repetitivos:

```java
// Interface ou classe base
public abstract class Usuario {
    public abstract boolean isAutenticado();
    public abstract String getNome();
    // ...
}

// Implementação real
@Entity
public class UsuarioReal extends Usuario {
    @Override
    public boolean isAutenticado() {
        return true;
    }

    @Override
    public String getNome() {
        return this.nome;
    }
}

// Null Object
public class UsuarioNaoLogado extends Usuario {
    @Override
    public boolean isAutenticado() {
        return false;
    }

    @Override
    public String getNome() {
        return "Anônimo";
    }
}
```

**Uso:**
```java
Usuario usuario = LogadoUtils.getUsuarioLogado();

// Ao invés de:
if (usuario == null) {
    throw new BusinessException("Não autenticado");
}

// Use:
if (!usuario.isAutenticado()) {
    throw new BusinessException("Não autenticado");
}

// Ou instanceof:
if (usuario instanceof UsuarioNaoLogado) {
    throw new BusinessException("Não autenticado");
}
```

### Enums com Interface

Para enums com valores de exibição amigáveis:

```java
public interface EnumExibicao {
    String getExibicao();
}

@Getter
@AllArgsConstructor
public enum TipoUsuario implements EnumExibicao {
    ADMINISTRADOR("Administrador"),
    GESTOR("Gestor"),
    CLIENTE("Cliente");

    private final String exibicao;

    @Override
    public String getExibicao() {
        return exibicao;
    }
}
```

**Uso no Response:**
```java
public record UsuarioResponse(
    Long id,
    String nome,
    String tipo,           // "ADMINISTRADOR"
    String tipoExibicao    // "Administrador"
) {
}

// No Adapter
return new UsuarioResponse(
    usuario.getId(),
    usuario.getNome(),
    usuario.getTipo().toString(),
    usuario.getTipo().getExibicao()
);
```

### Utility Classes com @UtilityClass (Lombok)

Para classes com apenas métodos estáticos:

```java
@UtilityClass
public class DateUtils {

    private static final DateTimeFormatter FORMATTER =
        DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public static LocalDate stringToLocalDate(String data) {
        if (data == null || data.isBlank()) return null;
        return LocalDate.parse(data, FORMATTER);
    }

    public static String localDateToString(LocalDate data) {
        if (data == null) return null;
        return data.format(FORMATTER);
    }
}
```

**Benefícios do @UtilityClass:**
- Torna a classe `final` automaticamente
- Construtor privado gerado
- Todos os métodos são `static`
- Evita instanciação acidental

### ApplicationRunner para Seed Data

Para inicializar dados na startup:

```java
@Configuration
public class DataInitializer {

    @Bean
    public ApplicationRunner initData(
        CategoriaService categoriaService,
        UsuarioService usuarioService
    ) {
        return args -> {
            log.info("Inicializando dados padrão...");

            // Criar usuário admin padrão
            usuarioService.criarUsuarioAdmin();

            // Criar categorias padrão
            categoriaService.criarCategoriasPadrao();

            log.info("Dados padrão inicializados com sucesso!");
        };
    }
}
```

**Uso com perfis:**
```java
@Bean
@Profile("!prod")  // Não executa em produção
public ApplicationRunner initMockData(EventoService eventoService) {
    return args -> {
        eventoService.criarEventosMock(10);
    };
}
```

---

## Boas Práticas de Segurança

### ⚠️ Nunca Hardcode Credenciais

**❌ Errado:**
```properties
spring.datasource.password=senha123
jwt.secret=minha-chave-secreta
aws.access-key=AKIAIOSFODNN7EXAMPLE
```

**✅ Correto:**
```properties
spring.datasource.password=${DB_PASSWORD}
jwt.secret=${JWT_SECRET}
aws.access-key=${AWS_ACCESS_KEY}
```

**application.yml com profiles:**
```yaml
spring:
  datasource:
    password: ${DB_PASSWORD}
  profiles:
    active: ${SPRING_PROFILE:dev}

---
spring:
  config:
    activate:
      on-profile: dev
  datasource:
    url: jdbc:mysql://localhost:3306/dev_db

---
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: ${DB_URL}
```

### Use Migrations (Flyway ou Liquibase)

**❌ Evite:**
```properties
spring.jpa.hibernate.ddl-auto=update  # Perigoso em produção
```

**✅ Use Flyway:**
```xml
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-mysql</artifactId>
</dependency>
```

```properties
spring.jpa.hibernate.ddl-auto=validate
spring.flyway.enabled=true
spring.flyway.baseline-on-migrate=true
```

**Migrations:**
```sql
-- src/main/resources/db/migration/V1__criar_tabela_usuario.sql
CREATE TABLE usuario (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    ativo CHAR(1) DEFAULT 'T',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modificado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### CORS Restritivo

**❌ Perigoso:**
```java
configuration.setAllowedOrigins(Arrays.asList("*"));
configuration.setAllowedMethods(Arrays.asList("*"));
```

**✅ Seguro:**
```java
@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins(
                        "https://app.exemplo.com",
                        "https://admin.exemplo.com"
                    )
                    .allowedMethods("GET", "POST", "PUT", "DELETE")
                    .allowedHeaders("Authorization", "Content-Type")
                    .exposedHeaders("Authorization")
                    .allowCredentials(true)
                    .maxAge(3600);
            }
        };
    }
}
```

**Com variável de ambiente:**
```java
@Value("${cors.allowed.origins}")
private String[] allowedOrigins;

registry.addMapping("/api/**")
    .allowedOrigins(allowedOrigins)
```

```properties
cors.allowed.origins=https://app.exemplo.com,https://admin.exemplo.com
```

### SQL Injection Prevention

**✅ Use JPQL com @Param:**
```java
@Query("SELECT u FROM Usuario u WHERE u.email = :email")
Optional<Usuario> findByEmail(@Param("email") String email);
```

**✅ Native queries com parâmetros:**
```java
@Query(value = "SELECT * FROM usuario WHERE email = :email", nativeQuery = true)
Optional<Usuario> findByEmailNative(@Param("email") String email);
```

**❌ NUNCA faça:**
```java
// String concatenation - vulnerável a SQL injection!
@Query(value = "SELECT * FROM usuario WHERE email = '" + email + "'", nativeQuery = true)
```

### Logging Seguro

**❌ Não logue dados sensíveis:**
```java
log.info("Usuário logado: {}, senha: {}", email, senha);  // NUNCA!
log.debug("Token JWT: {}", token);  // NUNCA!
```

**✅ Logue apenas informações seguras:**
```java
log.info("Usuário {} realizou login com sucesso", email);
log.debug("Token gerado para usuário ID: {}", usuarioId);
```

### Configurações por Ambiente

**application.properties:**
```properties
# Desenvolvimento
logging.level.org.hibernate.SQL=DEBUG
spring.jpa.show-sql=true
```

**application-prod.properties:**
```properties
# Produção
logging.level.org.hibernate.SQL=WARN
spring.jpa.show-sql=false
logging.level.root=INFO
```

### Rate Limiting

Use Bucket4j para limitar requisições:

```xml
<dependency>
    <groupId>com.github.vladimir-bukhtoyarov</groupId>
    <artifactId>bucket4j-core</artifactId>
    <version>8.1.0</version>
</dependency>
```

```java
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private final Map<String, Bucket> cache = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {

        String ip = request.getRemoteAddr();
        Bucket bucket = cache.computeIfAbsent(ip, k -> createBucket());

        if (bucket.tryConsume(1)) {
            filterChain.doFilter(request, response);
        } else {
            response.setStatus(429); // Too Many Requests
            response.getWriter().write("Rate limit exceeded");
        }
    }

    private Bucket createBucket() {
        // 100 requisições por minuto
        Bandwidth limit = Bandwidth.classic(100, Refill.intervally(100, Duration.ofMinutes(1)));
        return Bucket.builder().addLimit(limit).build();
    }
}
```

### Validação de Entrada

**Sempre valide inputs:**
```java
public record ClienteRequest(
    @NotBlank(message = "Nome é obrigatório")
    @Size(min = 3, max = 100, message = "Nome deve ter entre 3 e 100 caracteres")
    String nome,

    @Email(message = "E-mail inválido")
    String email,

    @Pattern(regexp = "^\\d{11}$", message = "CPF deve conter 11 dígitos")
    String cpf
) {
}
```

**Sanitize HTML:**
```xml
<dependency>
    <groupId>org.jsoup</groupId>
    <artifactId>jsoup</artifactId>
    <version>1.15.4</version>
</dependency>
```

```java
public String sanitizeHtml(String input) {
    return Jsoup.clean(input, Safelist.basic());
}
```
