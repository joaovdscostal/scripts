# Padrões - React

## 🔍 ANTES DE INICIAR

**IMPORTANTE**: Antes de começar a implementar ou modificar código neste projeto:

1. **Analise a estrutura de diretórios**: Mapeie `src/` - components, pages, hooks, services, types, utils
2. **Identifique componentes reutilizáveis**: Verifique `src/components/` para evitar duplicação (buttons, modals, forms, layouts)
3. **Leia configurações**: `vite.config.ts`, `tailwind.config.js`, `tsconfig.json`, `package.json`
4. **Verifique services existentes**: Como API é consumida, interceptors, tratamento de erros
5. **Entenda roteamento**: Estrutura de rotas em `App.tsx` ou arquivo de rotas, lazy loading, proteção de rotas
6. **Identifique hooks customizados**: Em `src/hooks/` - podem já existir hooks para autenticação, fetch, forms, etc
7. **Verifique tipos TypeScript**: Interfaces e types em `src/types/` para reutilizar
8. **Analise estado global**: Se usa Context API, Redux, Zustand - entenda o padrão adotado

**Só inicie a implementação após entender a organização, componentes existentes e padrões do projeto.**

---

## Stack
- React 18+
- TypeScript
- Vite
- Tailwind CSS
- React Router

## Estrutura
```
src/
├── components/
├── pages/
├── hooks/
├── services/
├── types/
└── utils/
```

## Convenções
- Componentes: PascalCase, functional components
- Hooks customizados: prefixo `use`
- Arquivos: kebab-case.tsx
- Props: TypeScript interfaces
- State: useState, useReducer
- Side effects: useEffect

## Estilização
- Tailwind utility classes
- Componentes reutilizáveis em /components
- Evitar CSS inline

## API
- Axios ou Fetch
- Services em /services
- Tipos das respostas em /types

## Roteamento
- React Router v6
- Rotas em arquivo separado
- Lazy loading para páginas

## Qualidade de Código

### Clean Code

- **Nomes descritivos**: variáveis, funções e componentes devem ser autoexplicativos
- **Funções pequenas**: cada função deve fazer uma única coisa
- **Sem código duplicado**: extrair para componentes, hooks ou utilitários reutilizáveis
- **Responsabilidade única**: cada componente com propósito claro
- **Código limpo e legível**: evitar complexidade desnecessária

### Design Patterns

- Aplicar padrões quando apropriado (Composition, HOC, Render Props, Compound Components, etc)
- Hooks customizados para lógica reutilizável
- Context API para estado compartilhado entre componentes distantes
- Não force patterns onde não fazem sentido

### Comentários

- **Código deve ser autoexplicativo** - comentários geralmente indicam código confuso
- Comentar apenas quando absolutamente necessário (lógica complexa inevitável, workarounds, TODOs)
- Preferir refatoração a comentários explicativos
- JSDoc para componentes públicos e funções complexas

### Idioma

- **Português por padrão** em todo o código
- Nomes de componentes, funções, variáveis em português
- Comentários e documentação em português
- Mensagens de erro, labels e textos de UI em português

---

## Stack Alternativas

Além do stack base (React + TypeScript + Vite + Tailwind), considere estas alternativas:

### UI Frameworks
- **Tailwind CSS** - Utility-first (padrão recomendado)
- **Bootstrap 5** + **React Bootstrap** - Componentes prontos
- **Material-UI** - Design System completo
- **Ant Design** - Enterprise UI
- **Metronic** - Template premium admin (comercial)

### State Management
- **TanStack Query** (React Query) - Estado servidor (recomendado para APIs)
- **Zustand** - Estado client leve
- **Redux Toolkit** - Estado global complexo
- **Context API** - Estado local/compartilhado simples
- **Jotai** - Atomic state

### Formulários
- **Formik + Yup** - Completo e maduro
- **React Hook Form + Zod** - Performance e type-safe
- Validação manual com useState

### Tabelas
- **TanStack Table** (React Table v8) - Headless, flexível
- **AG Grid** - Enterprise features
- Tabelas HTML simples

### HTTP Client
- **Axios** - Full-featured, interceptors
- **Fetch API** - Nativo do browser
- **TanStack Query** - Integra fetch com cache

### Notificações
- **React Toastify** - Toast simples
- **SweetAlert2** - Modals e toasts elegantes
- **Sonner** - Toast moderno
- Componentes customizados

---

## TanStack Query (React Query)

### Instalação e Setup

```bash
npm install @tanstack/react-query @tanstack/react-query-devtools
```

```typescript
// main.tsx ou App.tsx
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ReactQueryDevtools} from '@tanstack/react-query-devtools'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,  // Não refetch ao focar janela
      retry: 1,                      // Tentar 1x em caso de erro
      staleTime: 5 * 60 * 1000,      // Dados "frescos" por 5 minutos
    },
  },
})

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

### useQuery - Buscar Dados

**Query simples:**
```typescript
import {useQuery} from '@tanstack/react-query'
import {getUsers} from './services/userService'

function UsersList() {
  const {data, isLoading, error, refetch} = useQuery({
    queryKey: ['users'],
    queryFn: getUsers,
  })

  if (isLoading) return <div>Carregando...</div>
  if (error) return <div>Erro: {error.message}</div>

  return (
    <div>
      {data?.map(user => <div key={user.id}>{user.nome}</div>)}
      <button onClick={() => refetch()}>Atualizar</button>
    </div>
  )
}
```

**Query com parâmetros:**
```typescript
function UserDetail({userId}: {userId: number}) {
  const {data: user} = useQuery({
    queryKey: ['user', userId],  // Chave única por userId
    queryFn: () => getUserById(userId),
    enabled: !!userId,            // Só executa se userId existir
  })

  return <div>{user?.nome}</div>
}
```

**Query com paginação e filtros:**
```typescript
function UsersList() {
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')

  // Constrói query string
  const query = useMemo(() => {
    return qs.stringify({
      page,
      items_per_page: 10,
      search: search || undefined,
    }, {skipNulls: true})
  }, [page, search])

  const {data, isFetching} = useQuery({
    queryKey: ['users', query],
    queryFn: () => getUsers(query),
    placeholderData: keepPreviousData,  // Mantém dados antigos enquanto carrega novos
  })

  return (
    <>
      <input
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        placeholder="Buscar..."
      />
      {isFetching && <LoadingOverlay />}
      {data?.content.map(user => <UserRow key={user.id} user={user} />)}
      <Pagination
        currentPage={data?.currentPage}
        totalPages={data?.totalPages}
        onPageChange={setPage}
      />
    </>
  )
}
```

### useMutation - Modificar Dados

**Criar:**
```typescript
import {useMutation, useQueryClient} from '@tanstack/react-query'

function CreateUserForm() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: createUser,
    onSuccess: () => {
      // Invalida cache para refetch automático
      queryClient.invalidateQueries({queryKey: ['users']})
      showSuccess('Usuário criado!')
    },
    onError: (error: any) => {
      showError(error.response?.data?.message || 'Erro ao criar')
    },
  })

  const handleSubmit = (values: User) => {
    mutation.mutate(values)
  }

  return (
    <form onSubmit={handleSubmit}>
      {/* campos */}
      <button
        type="submit"
        disabled={mutation.isPending}
      >
        {mutation.isPending ? 'Salvando...' : 'Salvar'}
      </button>
    </form>
  )
}
```

**Atualizar:**
```typescript
const updateMutation = useMutation({
  mutationFn: ({id, data}: {id: number, data: User}) => updateUser(id, data),
  onSuccess: (updatedUser) => {
    // Atualiza cache diretamente (otimista)
    queryClient.setQueryData(['user', updatedUser.id], updatedUser)
    // Invalida lista
    queryClient.invalidateQueries({queryKey: ['users']})
  },
})

updateMutation.mutate({id: 1, data: formData})
```

**Deletar:**
```typescript
const deleteMutation = useMutation({
  mutationFn: deleteUser,
  onSuccess: (_, deletedId) => {
    // Remove do cache
    queryClient.removeQueries({queryKey: ['user', deletedId]})
    // Invalida lista
    queryClient.invalidateQueries({queryKey: ['users']})
    showSuccess('Usuário excluído!')
  },
})

const handleDelete = async (id: number) => {
  const confirmed = await showConfirm('Deseja excluir este usuário?')
  if (confirmed) {
    deleteMutation.mutate(id)
  }
}
```

### Provider Pattern com TanStack Query

**QueryResponseProvider:**
```typescript
import {FC, createContext, useContext, useState, useMemo} from 'react'
import {useQuery} from '@tanstack/react-query'
import {WithChildren} from '../types'

type QueryResponseContextProps = {
  response?: UsersResponse
  isLoading: boolean
  refetch: () => void
  query: string
}

const QueryResponseContext = createContext<QueryResponseContextProps>({
  response: undefined,
  isLoading: false,
  refetch: () => {},
  query: '',
})

export const QueryResponseProvider: FC<WithChildren> = ({children}) => {
  const {state} = useQueryRequest()  // Pega filtros, sort, página
  const [query, setQuery] = useState(buildQueryString(state))

  const {isFetching, refetch, data: response} = useQuery({
    queryKey: ['users', query],
    queryFn: () => getUsers(query),
  })

  useEffect(() => {
    setQuery(buildQueryString(state))
  }, [state])

  return (
    <QueryResponseContext.Provider value={{
      response,
      isLoading: isFetching,
      refetch,
      query
    }}>
      {children}
    </QueryResponseContext.Provider>
  )
}

export const useQueryResponse = () => useContext(QueryResponseContext)
```

**Uso:**
```typescript
function UsersPage() {
  return (
    <QueryRequestProvider>
      <QueryResponseProvider>
        <UsersListHeader />
        <UsersTable />
        <UsersListPagination />
      </QueryResponseProvider>
    </QueryRequestProvider>
  )
}

function UsersTable() {
  const {response, isLoading} = useQueryResponse()

  if (isLoading) return <Loading />

  return <Table data={response?.content} />
}
```

---

## Formik + Yup

### Instalação

```bash
npm install formik yup
```

### Formulário Completo

```typescript
import {useFormik} from 'formik'
import * as Yup from 'yup'
import clsx from 'clsx'

// 1. Schema de validação
const validationSchema = Yup.object().shape({
  login: Yup.string()
    .trim()
    .required('Usuário é obrigatório')
    .min(3, 'Use pelo menos 3 caracteres')
    .max(50, 'Use no máximo 50 caracteres'),

  email: Yup.string()
    .email('E-mail inválido')
    .nullable(),

  nome: Yup.string()
    .trim()
    .required('Nome é obrigatório'),

  tipoUsuario: Yup.string()
    .required('Selecione um perfil')
    .oneOf(['ADMINISTRADOR', 'GESTOR', 'CLIENTE']),

  // Validação condicional: senha obrigatória apenas em criação
  senha: Yup.string().when('id', {
    is: (id) => !id,  // Se não tem ID, é criação
    then: (schema) => schema
      .required('Senha é obrigatória')
      .min(6, 'Use pelo menos 6 caracteres'),
    otherwise: (schema) => schema.notRequired(),
  }),

  ativo: Yup.boolean(),
})

// 2. Valores iniciais
const initialValues: User = {
  login: '',
  email: '',
  nome: '',
  tipoUsuario: 'CLIENTE',
  senha: '',
  ativo: true,
}

// 3. Component
function UserForm({user, onClose}: Props) {
  const formik = useFormik({
    initialValues: user || initialValues,
    validationSchema,
    onSubmit: async (values, {setSubmitting}) => {
      setSubmitting(true)
      try {
        const isUpdate = !!values.id

        // Trim de strings
        const payload = {
          ...values,
          login: values.login.trim(),
          email: values.email?.trim() || undefined,
          senha: values.senha && values.senha.length > 0 ? values.senha : undefined,
        }

        if (isUpdate) {
          await updateUser(values.id, payload)
          showSuccess('Usuário atualizado!')
        } else {
          await createUser(payload)
          showSuccess('Usuário criado!')
        }

        onClose(true)  // Fecha modal e refetch
      } catch (error: any) {
        showError(error.response?.data?.message || 'Erro ao salvar')
      } finally {
        setSubmitting(false)
      }
    },
  })

  return (
    <form onSubmit={formik.handleSubmit} noValidate>
      {/* Input text */}
      <div className='mb-3'>
        <label className='form-label required'>Usuário</label>
        <input
          type='text'
          className={clsx(
            'form-control',
            {
              'is-invalid': formik.touched.login && formik.errors.login,
              'is-valid': formik.touched.login && !formik.errors.login && formik.values.login,
            }
          )}
          placeholder='ex: joao.silva'
          {...formik.getFieldProps('login')}
          disabled={formik.isSubmitting}
        />
        {formik.touched.login && formik.errors.login && (
          <div className='text-danger mt-1'>{formik.errors.login}</div>
        )}
      </div>

      {/* Select */}
      <div className='mb-3'>
        <label className='form-label required'>Perfil</label>
        <select
          className={clsx(
            'form-select',
            {'is-invalid': formik.touched.tipoUsuario && formik.errors.tipoUsuario}
          )}
          {...formik.getFieldProps('tipoUsuario')}
          disabled={formik.isSubmitting}
        >
          <option value=''>Selecione</option>
          <option value='ADMINISTRADOR'>Administrador</option>
          <option value='GESTOR'>Gestor</option>
          <option value='CLIENTE'>Cliente</option>
        </select>
        {formik.touched.tipoUsuario && formik.errors.tipoUsuario && (
          <div className='text-danger mt-1'>{formik.errors.tipoUsuario}</div>
        )}
      </div>

      {/* Checkbox/Switch */}
      <div className='form-check form-switch mb-3'>
        <input
          className='form-check-input'
          type='checkbox'
          id='user-ativo'
          checked={formik.values.ativo}
          onChange={(e) => formik.setFieldValue('ativo', e.target.checked)}
          disabled={formik.isSubmitting}
        />
        <label className='form-check-label' htmlFor='user-ativo'>
          {formik.values.ativo ? 'Ativo' : 'Inativo'}
        </label>
      </div>

      {/* Ações */}
      <div className='d-flex justify-content-end gap-2'>
        <button
          type='button'
          className='btn btn-light'
          onClick={() => onClose(false)}
          disabled={formik.isSubmitting}
        >
          Cancelar
        </button>
        <button
          type='submit'
          className='btn btn-primary'
          disabled={formik.isSubmitting || !formik.isValid}
        >
          {formik.isSubmitting ? 'Salvando...' : 'Salvar'}
        </button>
      </div>
    </form>
  )
}
```

### Validações Customizadas

**Validação assíncrona (check unicidade):**
```typescript
const validationSchema = Yup.object().shape({
  email: Yup.string()
    .email('E-mail inválido')
    .test('unique-email', 'E-mail já cadastrado', async (value) => {
      if (!value) return true
      const exists = await checkEmailExists(value)
      return !exists
    }),
})
```

**Validação com regex:**
```typescript
cpf: Yup.string()
  .matches(/^\d{11}$/, 'CPF deve conter 11 dígitos')
  .required('CPF é obrigatório'),

telefone: Yup.string()
  .matches(/^\(\d{2}\) \d{4,5}-\d{4}$/, 'Formato inválido. Use (XX) XXXXX-XXXX'),
```

**Validação de senha confirmação:**
```typescript
senha: Yup.string()
  .required('Senha é obrigatória')
  .min(8, 'Use pelo menos 8 caracteres'),

confirmarSenha: Yup.string()
  .oneOf([Yup.ref('senha')], 'As senhas devem ser iguais')
  .required('Confirme a senha'),
```

### Upload de Arquivo

```typescript
function UserFormWithPhoto() {
  const [uploadingPhoto, setUploadingPhoto] = useState(false)
  const [photoPreview, setPhotoPreview] = useState<string>()

  const formik = useFormik({
    // ... config
  })

  const handlePhotoUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file || !formik.values.id) return

    setUploadingPhoto(true)
    try {
      const updatedUser = await uploadFotoPerfil(formik.values.id, file)
      formik.setFieldValue('fotoPerfil', updatedUser.fotoPerfil)
      setPhotoPreview(updatedUser.fotoPerfil)
      showSuccess('Foto atualizada!')
    } catch (error) {
      showError('Erro ao fazer upload')
    } finally {
      setUploadingPhoto(false)
    }
  }

  return (
    <form onSubmit={formik.handleSubmit}>
      {/* Preview da foto */}
      <div className='mb-3'>
        <img
          src={photoPreview || formik.values.fotoPerfil || '/default-avatar.png'}
          alt='Preview'
          className='rounded-circle'
          style={{width: 100, height: 100, objectFit: 'cover'}}
        />
      </div>

      {/* Input file hidden */}
      <input
        type='file'
        accept='image/*'
        id='foto-upload'
        className='d-none'
        onChange={handlePhotoUpload}
        disabled={uploadingPhoto || formik.isSubmitting}
      />

      {/* Label como botão */}
      <label htmlFor='foto-upload' className='btn btn-light-primary btn-sm'>
        {uploadingPhoto ? 'Enviando...' : 'Alterar Foto'}
      </label>

      {/* Resto do formulário */}
    </form>
  )
}
```

---

## Axios e Interceptors

### Setup Axios

```typescript
// services/api.ts
import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8080'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

export default api
```

### Request Interceptor (Adicionar Token)

```typescript
import {getAuth} from './authService'

api.interceptors.request.use(
  (config) => {
    const auth = getAuth()

    if (auth?.token) {
      config.headers.Authorization = `Bearer ${auth.token}`
    }

    return config
  },
  (error) => Promise.reject(error)
)
```

### Response Interceptor (Refresh Token Automático)

```typescript
let isRefreshing = false
let failedQueue: any[] = []

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error)
    } else {
      prom.resolve(token)
    }
  })
  failedQueue = []
}

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config

    // 401: Token expirado - tentar refresh
    if (error.response?.status === 401 && !originalRequest._retry) {
      // Se já está fazendo refresh, adiciona na fila
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({resolve, reject})
        }).then((token) => {
          originalRequest.headers.Authorization = `Bearer ${token}`
          return api(originalRequest)
        })
      }

      originalRequest._retry = true
      isRefreshing = true

      const auth = getAuth()

      try {
        // Chama endpoint de refresh
        const {data} = await axios.post(`${API_BASE_URL}/auth/refresh-token`, {
          refreshToken: auth.refreshToken,
        })

        // Atualiza token no localStorage
        setAuth({
          token: data.token,
          refreshToken: data.refreshToken,
          usuario: auth.usuario,
        })

        // Processa fila de requisições pendentes
        processQueue(null, data.token)

        // Retenta request original
        originalRequest.headers.Authorization = `Bearer ${data.token}`
        return api(originalRequest)
      } catch (refreshError) {
        // Refresh falhou - faz logout
        processQueue(refreshError, null)
        removeAuth()
        window.location.href = '/auth/login'
        return Promise.reject(refreshError)
      } finally {
        isRefreshing = false
      }
    }

    // 403: Token inválido - logout imediato
    if (error.response?.status === 403) {
      removeAuth()
      window.location.href = '/auth/login'
    }

    return Promise.reject(error)
  }
)
```

### Services com Axios

```typescript
// services/userService.ts
import api from './api'
import qs from 'qs'

const USERS_ENDPOINT = '/api/usuarios/v1'

export type User = {
  id?: number
  login: string
  nome: string
  email?: string
  ativo: boolean
}

export type PageResponse<T> = {
  content: T[]
  currentPage: number
  pageSize: number
  totalElements: number
  totalPages: number
}

// GET com paginação e filtros
export const getUsers = async (queryString: string): Promise<PageResponse<User>> => {
  const params = qs.parse(queryString)
  const {data} = await api.get<PageResponse<User>>(USERS_ENDPOINT, {params})
  return data
}

// GET por ID
export const getUserById = async (id: number): Promise<User> => {
  const {data} = await api.get<User>(`${USERS_ENDPOINT}/${id}`)
  return data
}

// POST
export const createUser = async (user: User): Promise<User> => {
  const {data} = await api.post<User>(USERS_ENDPOINT, user)
  return data
}

// PUT
export const updateUser = async (id: number, user: User): Promise<User> => {
  const {data} = await api.put<User>(`${USERS_ENDPOINT}/${id}`, user)
  return data
}

// DELETE
export const deleteUser = async (id: number): Promise<void> => {
  await api.delete(`${USERS_ENDPOINT}/${id}`)
}

// Upload multipart/form-data
export const uploadFotoPerfil = async (userId: number, file: File): Promise<User> => {
  const formData = new FormData()
  formData.append('file', file)

  const {data} = await api.post<User>(
    `${USERS_ENDPOINT}/${userId}/foto-perfil`,
    formData,
    {
      headers: {'Content-Type': 'multipart/form-data'},
    }
  )
  return data
}
```

---

## TanStack Table (React Table)

### Instalação

```bash
npm install @tanstack/react-table
```

### Definição de Colunas

```typescript
import {ColumnDef} from '@tanstack/react-table'
import {User} from '../types'

export const usersColumns: ColumnDef<User>[] = [
  // Coluna de seleção
  {
    id: 'selection',
    header: ({table}) => (
      <input
        type='checkbox'
        checked={table.getIsAllRowsSelected()}
        onChange={table.getToggleAllRowsSelectedHandler()}
      />
    ),
    cell: ({row}) => (
      <input
        type='checkbox'
        checked={row.getIsSelected()}
        onChange={row.getToggleSelectedHandler()}
      />
    ),
  },

  // Coluna com accessor simples
  {
    accessorKey: 'login',
    header: 'Usuário',
    cell: (info) => info.getValue(),
  },

  // Coluna com renderização customizada
  {
    id: 'name',
    header: 'Nome Completo',
    cell: ({row}) => {
      const user = row.original
      return (
        <div className='d-flex align-items-center'>
          <img
            src={user.fotoPerfil || '/default-avatar.png'}
            alt={user.nome}
            className='rounded-circle me-2'
            style={{width: 32, height: 32}}
          />
          <div>
            <div className='fw-bold'>{user.nome}</div>
            <div className='text-muted small'>{user.email}</div>
          </div>
        </div>
      )
    },
  },

  // Coluna com sorting customizado
  {
    accessorKey: 'tipoUsuario',
    header: ({column}) => (
      <div
        onClick={column.getToggleSortingHandler()}
        style={{cursor: 'pointer'}}
      >
        Perfil {column.getIsSorted() === 'asc' ? '↑' : column.getIsSorted() === 'desc' ? '↓' : ''}
      </div>
    ),
    cell: (info) => {
      const tipo = info.getValue() as string
      const labels = {
        ADMINISTRADOR: 'Administrador',
        GESTOR: 'Gestor',
        CLIENTE: 'Cliente',
      }
      return labels[tipo] || tipo
    },
  },

  // Coluna com badge
  {
    accessorKey: 'ativo',
    header: 'Status',
    cell: (info) => {
      const ativo = info.getValue() as boolean
      return (
        <span className={`badge badge-light-${ativo ? 'success' : 'danger'}`}>
          {ativo ? 'Ativo' : 'Inativo'}
        </span>
      )
    },
  },

  // Coluna de ações
  {
    id: 'actions',
    header: 'Ações',
    cell: ({row}) => {
      const user = row.original
      return (
        <div className='d-flex gap-2'>
          <button
            className='btn btn-sm btn-light-primary'
            onClick={() => handleEdit(user)}
          >
            Editar
          </button>
          <button
            className='btn btn-sm btn-light-danger'
            onClick={() => handleDelete(user.id)}
          >
            Excluir
          </button>
        </div>
      )
    },
  },
]
```

### Componente de Tabela

```typescript
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  flexRender,
} from '@tanstack/react-table'
import {useMemo, useState} from 'react'
import {usersColumns} from './columns'

function UsersTable() {
  const {response, isLoading} = useQueryResponse()
  const [sorting, setSorting] = useState([])
  const [rowSelection, setRowSelection] = useState({})

  const data = useMemo(() => response?.content ?? [], [response])

  const table = useReactTable({
    data,
    columns: usersColumns,
    state: {
      sorting,
      rowSelection,
    },
    onSortingChange: setSorting,
    onRowSelectionChange: setRowSelection,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    manualPagination: true,  // Paginação no servidor
  })

  if (isLoading) return <Loading />

  return (
    <div className='table-responsive'>
      <table className='table table-hover'>
        <thead>
          {table.getHeaderGroups().map((headerGroup) => (
            <tr key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <th key={header.id}>
                  {flexRender(
                    header.column.columnDef.header,
                    header.getContext()
                  )}
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody>
          {table.getRowModel().rows.map((row) => (
            <tr key={row.id}>
              {row.getVisibleCells().map((cell) => (
                <td key={cell.id}>
                  {flexRender(
                    cell.column.columnDef.cell,
                    cell.getContext()
                  )}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>

      {/* Informações de seleção */}
      {Object.keys(rowSelection).length > 0 && (
        <div className='alert alert-info'>
          {Object.keys(rowSelection).length} item(ns) selecionado(s)
        </div>
      )}
    </div>
  )
}
```

---

## Provider Pattern e Hooks Customizados

### Context + Provider + Hook

```typescript
import {FC, createContext, useContext, useState} from 'react'

// 1. Define o tipo do contexto
type ListViewContextProps = {
  selected: number[]
  itemIdForUpdate?: number
  setItemIdForUpdate: (id?: number) => void
  onSelect: (id: number) => void
  onSelectAll: () => void
  clearSelected: () => void
  isAllSelected: boolean
}

// 2. Cria o contexto com valores iniciais
const ListViewContext = createContext<ListViewContextProps>({
  selected: [],
  setItemIdForUpdate: () => {},
  onSelect: () => {},
  onSelectAll: () => {},
  clearSelected: () => {},
  isAllSelected: false,
})

// 3. Cria o Provider
export const ListViewProvider: FC<{children: React.ReactNode}> = ({children}) => {
  const [selected, setSelected] = useState<number[]>([])
  const [itemIdForUpdate, setItemIdForUpdate] = useState<number>()
  const {response} = useQueryResponse()  // Hook de outro provider

  const onSelect = (id: number) => {
    setSelected((prev) =>
      prev.includes(id)
        ? prev.filter((item) => item !== id)
        : [...prev, id]
    )
  }

  const onSelectAll = () => {
    if (!response?.content) return

    if (isAllSelected) {
      setSelected([])
    } else {
      setSelected(response.content.map((item) => item.id))
    }
  }

  const clearSelected = () => setSelected([])

  const isAllSelected = useMemo(() => {
    if (!response?.content?.length) return false
    return selected.length === response.content.length
  }, [selected, response])

  return (
    <ListViewContext.Provider value={{
      selected,
      itemIdForUpdate,
      setItemIdForUpdate,
      onSelect,
      onSelectAll,
      clearSelected,
      isAllSelected,
    }}>
      {children}
    </ListViewContext.Provider>
  )
}

// 4. Exporta hook customizado
export const useListView = () => {
  const context = useContext(ListViewContext)
  if (!context) {
    throw new Error('useListView must be used within ListViewProvider')
  }
  return context
}
```

### Uso do Provider

```typescript
function UsersPage() {
  return (
    <QueryRequestProvider>
      <QueryResponseProvider>
        <ListViewProvider>
          <UsersListHeader />
          <UsersTable />
          <UsersListToolbar />
        </ListViewProvider>
      </QueryResponseProvider>
    </QueryRequestProvider>
  )
}

function UsersListToolbar() {
  const {selected, clearSelected} = useListView()
  const deleteMutation = useMutation({mutationFn: deleteUsers})

  const handleDeleteSelected = async () => {
    const confirmed = await showConfirm(`Excluir ${selected.length} usuário(s)?`)
    if (confirmed) {
      await deleteMutation.mutateAsync(selected)
      clearSelected()
    }
  }

  if (selected.length === 0) return null

  return (
    <div className='alert alert-warning d-flex justify-content-between'>
      <span>{selected.length} selecionado(s)</span>
      <button className='btn btn-danger btn-sm' onClick={handleDeleteSelected}>
        Excluir Selecionados
      </button>
    </div>
  )
}
```

### Hook customizado useDebounce

```typescript
import {useState, useEffect} from 'react'

export function useDebounce<T>(value: T, delay: number = 500): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => {
      clearTimeout(handler)
    }
  }, [value, delay])

  return debouncedValue
}

// Uso
function SearchInput() {
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search, 500)

  useEffect(() => {
    if (debouncedSearch) {
      // Executa busca apenas 500ms após parar de digitar
      fetchResults(debouncedSearch)
    }
  }, [debouncedSearch])

  return (
    <input
      value={search}
      onChange={(e) => setSearch(e.target.value)}
      placeholder="Buscar..."
    />
  )
}
```

---

## Estrutura CRUD Padronizada

Organize CRUDs complexos por feature com estrutura consistente:

```
src/modules/user-management/
├── UsersPage.tsx              # Wrapper da página
└── users-list/
    ├── core/                  # Lógica de negócio
    │   ├── _models.ts         # Types (User, UsersQueryResponse, initialUser)
    │   ├── _requests.ts       # API calls (getUsers, createUser, updateUser, deleteUser)
    │   ├── ListViewProvider.tsx       # Seleção em massa
    │   ├── QueryRequestProvider.tsx   # Request state (filtros, sort, página)
    │   └── QueryResponseProvider.tsx  # Response state (TanStack Query)
    │
    ├── components/            # Componentes de UI
    │   ├── header/
    │   │   ├── UsersListHeader.tsx          # Botão "Novo", título
    │   │   ├── UsersListToolbar.tsx         # Ações em massa
    │   │   └── UsersListSearchComponent.tsx # Busca e filtros
    │   ├── loading/
    │   │   └── UsersListLoading.tsx         # Loading overlay
    │   └── pagination/
    │       └── UsersListPagination.tsx      # Paginação customizada
    │
    ├── table/
    │   ├── UsersTable.tsx     # Componente de tabela (TanStack Table)
    │   └── columns/
    │       ├── _columns.tsx               # Definição de colunas
    │       ├── UserActionsCell.tsx        # Ações (editar, deletar)
    │       ├── UserCustomHeader.tsx       # Header com sort
    │       ├── UserInfoCell.tsx           # Célula principal
    │       └── UserSelectionCell.tsx      # Checkbox de seleção
    │
    └── user-edit-modal/
        ├── UserEditModal.tsx              # Modal wrapper
        ├── UserEditModalForm.tsx          # Formulário (Formik + Yup)
        ├── UserEditModalHeader.tsx        # Header do modal
        └── UserEditModalFormWrapper.tsx   # Wrapper com loading
```

### _models.ts

```typescript
export type User = {
  id?: number
  login: string
  nome: string
  email?: string
  tipoUsuario: 'ADMINISTRADOR' | 'GESTOR' | 'CLIENTE'
  ativo: boolean
  fotoPerfil?: string
  criadoEm?: string
}

export const initialUser: User = {
  login: '',
  nome: '',
  email: '',
  tipoUsuario: 'CLIENTE',
  ativo: true,
}

export type UsersQueryResponse = {
  content: User[]
  currentPage: number
  pageSize: number
  totalElements: number
  totalPages: number
}
```

### _requests.ts

```typescript
import api from '../../../services/api'
import qs from 'qs'

const USERS_ENDPOINT = '/api/usuarios/v1'

export const getUsers = async (queryString: string) => {
  const params = qs.parse(queryString)
  const {data} = await api.get(USERS_ENDPOINT, {params})
  return data
}

export const createUser = async (user: User) => {
  const {data} = await api.post(USERS_ENDPOINT, user)
  return data
}

export const updateUser = async (id: number, user: User) => {
  const {data} = await api.put(`${USERS_ENDPOINT}/${id}`, user)
  return data
}

export const deleteUser = async (id: number) => {
  await api.delete(`${USERS_ENDPOINT}/${id}`)
}
```

### UsersPage.tsx (Wrapper)

```typescript
import {ListViewProvider} from './users-list/core/ListViewProvider'
import {QueryRequestProvider} from './users-list/core/QueryRequestProvider'
import {QueryResponseProvider} from './users-list/core/QueryResponseProvider'
import {UsersListHeader} from './users-list/components/header/UsersListHeader'
import {UsersTable} from './users-list/table/UsersTable'
import {UserEditModal} from './users-list/user-edit-modal/UserEditModal'
import {KTCard} from '../../../_metronic/helpers'

export function UsersPage() {
  return (
    <QueryRequestProvider>
      <QueryResponseProvider>
        <ListViewProvider>
          <KTCard>
            <UsersListHeader />
            <UsersTable />
          </KTCard>
          <UserEditModal />
        </ListViewProvider>
      </QueryResponseProvider>
    </QueryRequestProvider>
  )
}
```

---

## Notificações (SweetAlert2)

### Instalação

```bash
npm install sweetalert2
```

### Helper de Notificações

```typescript
// utils/NotificationHelper.ts
import Swal, {SweetAlertIcon} from 'sweetalert2'

const Toast = Swal.mixin({
  toast: true,
  position: 'bottom-end',
  showConfirmButton: false,
  timer: 3000,
  timerProgressBar: true,
})

export const showSuccess = (message: string) => {
  Toast.fire({
    icon: 'success',
    title: message,
  })
}

export const showError = (message: string) => {
  Toast.fire({
    icon: 'error',
    title: message,
    timer: 4000,
  })
}

export const showWarning = (message: string) => {
  Toast.fire({
    icon: 'warning',
    title: message,
    timer: 3500,
  })
}

export const showInfo = (message: string) => {
  Toast.fire({
    icon: 'info',
    title: message,
  })
}

export const showConfirm = async (
  message: string,
  title: string = 'Confirmar'
): Promise<boolean> => {
  const result = await Swal.fire({
    title,
    text: message,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Confirmar',
    cancelButtonText: 'Cancelar',
    confirmButtonColor: '#3085d6',
    cancelButtonColor: '#d33',
  })

  return result.isConfirmed
}

export const showDeleteConfirm = async (
  itemName: string = 'este item',
  title: string = 'Confirmar Exclusão'
): Promise<boolean> => {
  const result = await Swal.fire({
    title,
    text: `Tem certeza que deseja excluir ${itemName}? Esta ação não pode ser desfeita.`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Sim, excluir',
    cancelButtonText: 'Cancelar',
    confirmButtonColor: '#d33',
    cancelButtonColor: '#3085d6',
  })

  return result.isConfirmed
}

export const showLoading = (message: string = 'Carregando...') => {
  Swal.fire({
    title: message,
    allowOutsideClick: false,
    didOpen: () => {
      Swal.showLoading()
    },
  })
}

export const closeLoading = () => {
  Swal.close()
}
```

### Uso

```typescript
import {showSuccess, showError, showConfirm, showDeleteConfirm} from './utils/NotificationHelper'

// Toast simples (NÃO usar await)
showSuccess('Usuário criado!')
showError('Erro ao salvar')
showWarning('Alguns campos estão vazios')
showInfo('Processamento em andamento')

// Confirmação (USAR await)
const handleDelete = async (id: number) => {
  const confirmed = await showDeleteConfirm('este usuário')

  if (confirmed) {
    try {
      await deleteUser(id)
      showSuccess('Usuário excluído!')
    } catch (error) {
      showError('Erro ao excluir')
    }
  }
}

// Confirmação customizada
const handleAction = async () => {
  const confirmed = await showConfirm(
    'Esta ação irá notificar todos os usuários',
    'Enviar Notificações?'
  )

  if (confirmed) {
    await sendNotifications()
  }
}

// Loading global
const processData = async () => {
  showLoading('Processando dados...')

  try {
    await longRunningOperation()
    closeLoading()
    showSuccess('Processamento concluído!')
  } catch (error) {
    closeLoading()
    showError('Erro no processamento')
  }
}
```

---

## Utilitários Comuns

### clsx para Classes Condicionais

```bash
npm install clsx
```

```typescript
import clsx from 'clsx'

<div
  className={clsx(
    'form-control',  // Sempre
    {'is-invalid': touched && error},  // Condicional
    {'is-valid': touched && !error && value},  // Condicional
    size === 'lg' && 'form-control-lg',  // Condicional inline
  )}
/>

// Também aceita arrays
<div
  className={clsx([
    'btn',
    variant === 'primary' && 'btn-primary',
    variant === 'secondary' && 'btn-secondary',
    size && `btn-${size}`,
    disabled && 'disabled',
  ])}
/>
```

### Query String (qs)

```bash
npm install qs
```

```typescript
import qs from 'qs'

// Serialização
const params = {
  page: 1,
  items_per_page: 10,
  sort: 'nome',
  order: 'asc',
  search: 'joão',
  filter_ativo: true,
}

const queryString = qs.stringify(params, {
  skipNulls: true,           // Ignora valores null/undefined
  arrayFormat: 'brackets',   // arrays: filter[]=1&filter[]=2
})
// Resultado: "page=1&items_per_page=10&sort=nome&order=asc&search=joão&filter_ativo=true"

// Parse
const parsed = qs.parse('page=1&items_per_page=10')
// Resultado: {page: '1', items_per_page: '10'}
```

### isNotEmpty Helper

```typescript
export const isNotEmpty = (value: any): boolean => {
  return value !== undefined && value !== null && value !== ''
}

// Uso
const isUpdate = isNotEmpty(user.id)

if (isNotEmpty(searchTerm)) {
  // Executar busca
}
```

---

## Lazy Loading e Code Splitting

### React.lazy + Suspense

```typescript
import {lazy, Suspense} from 'react'
import {Routes, Route} from 'react-router-dom'
import TopBarProgress from 'react-topbar-progress-indicator'

// Componentes lazy
const UsersPage = lazy(() => import('./modules/user-management/UsersPage'))
const DashboardPage = lazy(() => import('./pages/dashboard/DashboardWrapper'))
const ProfilePage = lazy(() => import('./pages/profile/ProfilePage'))

// Wrapper de suspense com loading
function SuspensedView({children}: {children: React.ReactNode}) {
  return <Suspense fallback={<TopBarProgress />}>{children}</Suspense>
}

// Rotas
export function AppRoutes() {
  return (
    <Routes>
      <Route
        path='/dashboard'
        element={
          <SuspensedView>
            <DashboardPage />
          </SuspensedView>
        }
      />
      <Route
        path='/users/*'
        element={
          <SuspensedView>
            <UsersPage />
          </SuspensedView>
        }
      />
    </Routes>
  )
}
```

### Pré-carregamento (Prefetch)

```typescript
// Pré-carrega ao hover
const UsersLink = () => {
  const prefetchUsers = () => {
    import('./modules/user-management/UsersPage')
  }

  return (
    <Link
      to='/users'
      onMouseEnter={prefetchUsers}
      onFocus={prefetchUsers}
    >
      Usuários
    </Link>
  )
}
```

---

## Boas Práticas Específicas React

### Organização de Imports

```typescript
// 1. React e hooks
import {FC, useState, useEffect, useMemo} from 'react'

// 2. React Router
import {useNavigate, useParams} from 'react-router-dom'

// 3. Bibliotecas externas
import {useFormik} from 'formik'
import * as Yup from 'yup'
import clsx from 'clsx'

// 4. TanStack Query
import {useQuery, useMutation, useQueryClient} from '@tanstack/react-query'

// 5. Componentes de UI
import {Modal, Button} from 'react-bootstrap'

// 6. Componentes internos
import {UserCard} from './UserCard'
import {Loading} from '@/components/Loading'

// 7. Hooks customizados
import {useAuth} from '@/hooks/useAuth'
import {useListView} from '../core/ListViewProvider'

// 8. Types
import {User} from '../core/_models'

// 9. Services
import {createUser, updateUser} from '../core/_requests'

// 10. Utils
import {showSuccess, showError} from '@/utils/NotificationHelper'

// 11. Estilos (último)
import './styles.scss'
```

### Nomenclatura React

**Componentes:** PascalCase
```typescript
UserEditModal.tsx
DashboardWrapper.tsx
UsersListHeader.tsx
```

**Hooks:** camelCase com prefixo `use`
```typescript
useAuth.ts
useDebounce.ts
useListView.ts
```

**Types/Models:** com `_` prefixo
```typescript
_models.ts
_requests.ts
```

**Utils:** camelCase
```typescript
notificationHelper.ts
dateUtils.ts
```

### Evitar Re-renders Desnecessários

**useMemo:**
```typescript
const filteredUsers = useMemo(() => {
  if (!search) return users
  return users.filter(u => u.nome.includes(search))
}, [users, search])
```

**useCallback:**
```typescript
const handleSearch = useCallback((value: string) => {
  setSearch(value)
  refetch()
}, [refetch])
```

**React.memo:**
```typescript
const UserRow = React.memo(({user}: {user: User}) => {
  return <tr>...</tr>
})
```

### Tratamento de Erros em APIs

```typescript
const mutation = useMutation({
  mutationFn: createUser,
  onSuccess: () => {
    showSuccess('Usuário criado!')
    queryClient.invalidateQueries({queryKey: ['users']})
  },
  onError: (error: any) => {
    // Trata diferentes tipos de erro
    if (error.response?.status === 400) {
      showError(error.response.data.message || 'Dados inválidos')
    } else if (error.response?.status === 409) {
      showError('Usuário já existe')
    } else if (error.response?.status === 403) {
      showError('Você não tem permissão')
    } else {
      showError('Erro ao criar usuário')
    }
  },
})
```

### TypeScript com Props

**Props com interface:**
```typescript
interface UserCardProps {
  user: User
  onEdit: (id: number) => void
  onDelete: (id: number) => void
  className?: string
}

const UserCard: FC<UserCardProps> = ({user, onEdit, onDelete, className}) => {
  return <div className={className}>...</div>
}
```

**Props com children:**
```typescript
type WithChildren = {
  children: React.ReactNode
}

const Container: FC<WithChildren> = ({children}) => {
  return <div className='container'>{children}</div>
}
```

**Props com generics:**
```typescript
interface PageResponseProps<T> {
  data: T[]
  renderItem: (item: T) => React.ReactNode
}

function PageResponse<T>({data, renderItem}: PageResponseProps<T>) {
  return <div>{data.map(renderItem)}</div>
}
```
