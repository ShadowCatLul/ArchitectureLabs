workspace {
    name "Сервис поиска попутчиков"
    description "Данный сервис предназначен для поиска попутчиков и включает следующие функции:\
    - Возможность для водителя создать маршрут\
    - Возможность для попутчика создать поездку\
    - Возможность для водителя и попутчика найти друг друга по маршруту и поездке"

    !identifiers hierarchical

    model {
        properties { 
            structurizr.groupSeparator "/"
        }
        
        user_driver = person "Водитель"
        user_passenger = person "Пассажир-попутчик"

        MainService = softwareSystem "MainService" {
            description "Система для сопоставления водителей и пассажиров"

            proxy = container "Proxy service" {
                description "Прокси-сервис для перенаправления запросов"
            }

            client_service = container "Client Service" {
                description "Сервис для управления данными клиентов"

                api = component "API" {
                    description "Интерфейс программирования приложений"
                    technology "Python"
                    tags "API"
                }

                clients_database = component "Clients Database" {
                    description "База данных клиентов"
                    technology "PostgreSQL"
                    tags "database"
                }  

                api -> clients_database "Запись данных о пользователях"
                clients_database -> api "Авторизация и поиск пользователей"
            }

            path_service = container "Path tracker" {
                description "Сервис для отслеживания маршрутов и поездок"

                api = component "API" {
                    description "Интерфейс программирования приложений"
                    technology "Python"
                    tags "API"
                }

                group "Слой хранения" {
                    route_table = component "Route table" {
                        description "Таблица маршрутов водителей"
                        technology "PostgreSQL"
                        tags "database"
                    }

                    travel_table = component "Travel table" {
                        description "Таблица поездок пассажиров"
                        technology "PostgreSQL"
                        tags "database"
                    }
                }

                route_travel_searcher = component "Search worker" {
                    description "Фоновый процесс для поиска подходящих попутчиков"
                    technology "Python"
                    tags "worker"
                }

                result_database = component "Result database" {
                    description "База данных для хранения результатов сопоставления маршрутов и попутчиков"
                    technology "Redis"
                    tags "database"
                }

                api -> route_table "Регистрация маршрутов"
                api -> travel_table "Регистрация поездок"

                route_travel_searcher -> route_table "Поиск подходящих поездок для маршрутов"
                route_travel_searcher -> travel_table "Поиск подходящих маршрутов для поездок"

                route_travel_searcher -> result_database "Связывание попутчиков с маршрутами" 

                result_database -> api "Возврат результатов пользователям"
            }

            proxy -> client_service "Регистрация и поиск пользователей, авторизация"
            client_service -> proxy "Возврат client_id при создании/авторизации пользователя"

            proxy -> path_service "Управление маршрутами и поездками, связывание поездок с маршрутами"
            
        }

        user_driver -> MainService "Обмен данными между водителем и сервисом через API"
        user_driver -> MainService.proxy "Обмен данными между водителем и сервисом через API"
        user_passenger -> MainService "Обмен данными между пассажиром и сервисом через API"
        user_passenger -> MainService.proxy "Обмен данными между пассажиром и сервисом через API"



        produсtion = deploymentEnvironment "Production" {
            deploymentGroup "MainService prod"

            client_service = deploymentNode "Client Services" {
                containerInstance MainService.client_service
            }

            path_service = deploymentNode "Path service" {
                containerInstance MainService.path_service
            }

            proxy = deploymentNode "Proxy" {
                containerInstance MainService.proxy
            }

            client_service -> proxy
            path_service -> proxy
        }
    }

    views {
        systemContext MainService {
            autoLayout
            include *
        }

        container MainService {
            autoLayout
            include *
        }

        component MainService.path_service {
            include *
        }

        component MainService.client_service {
            autoLayout
            include *
        }

        dynamic MainService "UC01" "Создание нового пользователя или авторизация" {
            autoLayout

            user_driver -> MainService.proxy "POST CreateUser/Authorize"
            user_passenger -> MainService.proxy "POST CreateUser/Authorize"

            MainService.proxy -> MainService.client_service "Перенаправление запроса"
        }

        dynamic MainService "UC02" "Поиск пользователя по логину или маске (имя, фамилия)" {
            autoLayout

            user_driver -> MainService.proxy "GET UserByUsername/UserByFirstName"
            user_passenger -> MainService.proxy "GET UserByUsername/UserByFirstName"

            MainService.proxy -> MainService.client_service "Перенаправление запроса"
        }

        dynamic MainService "UC11" "Создание маршрута/поездки" {
            autoLayout

            user_driver -> MainService.proxy "POST CreateRoute"
            user_passenger -> MainService.proxy "POST CreateTravel"
            
            MainService.proxy -> MainService.path_service "Перенаправление запроса (client_id)"
        }

        dynamic MainService "UC12" "Получение маршрутов пользователя" {
            autoLayout

            user_driver -> MainService.proxy "GET UserRoute (client_id)"

            MainService.proxy -> MainService.path_service "Перенаправление запроса (client_id)"
        }

        dynamic MainService "UC13" "Получение информации о поездке" {
            autoLayout

            user_driver -> MainService.proxy "GET UserTravel (client_id)"

            MainService.proxy -> MainService.path_service "Перенаправление запроса (client_id)"
        }

        dynamic MainService "UC14" "Подключение пользователя к поездке" {
            autoLayout

            MainService.path_service -> MainService.proxy "Сигнал об обновлении статуса поездки"

            MainService.proxy -> user_driver  "[polling] GET UserRoute (client_id)"
            MainService.proxy -> user_passenger  "[polling] GET UserTravel (client_id)"
        }

        deployment MainService produсtion {
            autoLayout
            include *
        }

        theme default
        

        styles {
            element "database" {
                shape cylinder
            }

            element "API" {
                shape Pipe
            }
        }
    }
}
