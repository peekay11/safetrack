export const openApiSpec = {
  openapi: '3.0.3',
  info: {
    title: 'SafeTrack Cloudflare Edge API',
    version: '1.0.0',
    description:
      'Backend API for SafeWalk/SafeTrack: Walking-group formation, Guardian Angel escort, SOS distress dispatch, live tracking, E-Hailing protection, and USSD incident reporting.',
  },
  servers: [
    {
      url: 'https://safetrack-backend.pasekamabitsela22.workers.dev',
      description: 'Cloudflare Workers Production',
    },
    {
      url: 'http://localhost:8787',
      description: 'Local Development',
    },
  ],
  components: {
    securitySchemes: {
      BearerAuth: {
        type: 'http',
        scheme: 'bearer',
        description: 'Session token returned from /api/auth/verify-otp',
      },
    },
  },
  paths: {
    '/': {
      get: {
        summary: 'Root Health Check',
        responses: {
          '200': { description: 'API status and available modules' },
        },
      },
    },
    '/api/auth/send-otp': {
      post: {
        summary: 'Send Phone OTP',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['phone_number'],
                properties: {
                  phone_number: { type: 'string', example: '+27821234567' },
                },
              },
            },
          },
        },
        responses: {
          '200': { description: 'OTP sent' },
        },
      },
    },
    '/api/auth/verify-otp': {
      post: {
        summary: 'Verify OTP & Authenticate',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['phone_number', 'code'],
                properties: {
                  phone_number: { type: 'string', example: '+27821234567' },
                  code: { type: 'string', example: '123456' },
                  full_name: { type: 'string', example: 'Thandi Khumalo' },
                },
              },
            },
          },
        },
        responses: {
          '200': { description: 'Authenticated successfully with session token' },
        },
      },
    },
    '/api/auth/me': {
      get: {
        summary: 'Get Current User Profile & Guardian Angels',
        security: [{ BearerAuth: [] }],
        responses: {
          '200': { description: 'User profile and guardian angels list' },
          '401': { description: 'Unauthorized' },
        },
      },
    },
    '/api/auth/profile': {
      patch: {
        summary: 'Update Profile & Accessibility Settings',
        security: [{ BearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  full_name: { type: 'string' },
                  id_number: { type: 'string' },
                  id_type: { type: 'string', enum: ['sa_id', 'passport', 'drivers_license'] },
                  language: { type: 'string', enum: ['en', 'zu', 'af', 'st'] },
                  needs_extra_time: { type: 'boolean' },
                  guardian_angel_primary: { type: 'boolean' },
                },
              },
            },
          },
        },
        responses: {
          '200': { description: 'Profile updated' },
        },
      },
    },
    '/api/guardians': {
      get: {
        summary: 'List Guardian Angels',
        security: [{ BearerAuth: [] }],
        responses: {
          '200': { description: 'List of Guardian Angels (up to 4)' },
        },
      },
      post: {
        summary: 'Add Guardian Angel Contact',
        security: [{ BearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['name', 'phone_number'],
                properties: {
                  name: { type: 'string', example: 'Sis Nomvula' },
                  phone_number: { type: 'string', example: '+27839876543' },
                  relationship: { type: 'string', example: 'Sister' },
                  gender: { type: 'string', enum: ['female', 'male', 'other'] },
                  night_only: { type: 'boolean', example: false },
                },
              },
            },
          },
        },
        responses: {
          '201': { description: 'Guardian Angel added' },
        },
      },
    },
    '/api/groups/destinations': {
      get: {
        summary: 'List Destinations (Taxi ranks, malls, stations)',
        responses: {
          '200': { description: 'List of preset destinations' },
        },
      },
    },
    '/api/groups/match': {
      post: {
        summary: 'Match into Walking Group (100–500m proximity)',
        security: [{ BearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['destination_id', 'latitude', 'longitude'],
                properties: {
                  destination_id: { type: 'string', example: 'dest-bree-taxi' },
                  latitude: { type: 'number', example: -26.2041 },
                  longitude: { type: 'number', example: 28.0473 },
                  planned_departure_time: { type: 'string', example: '2026-09-18T14:00:00Z' },
                },
              },
            },
          },
        },
        responses: {
          '200': { description: 'Group matched or created' },
        },
      },
    },
    '/api/groups/{id}': {
      get: {
        summary: 'Get Group Roster & Pickups',
        security: [{ BearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: {
          '200': { description: 'Group details and members' },
        },
      },
    },
    '/api/groups/{id}/location': {
      post: {
        summary: 'Update Live Location in Group (KV)',
        security: [{ BearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['latitude', 'longitude'],
                properties: {
                  latitude: { type: 'number', example: -26.2041 },
                  longitude: { type: 'number', example: 28.0473 },
                },
              },
            },
          },
        },
        responses: { '200': { description: 'Location updated' } },
      },
    },
    '/api/groups/{id}/locations': {
      get: {
        summary: 'Get All Members Live Locations',
        security: [{ BearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'Live coordinates map' } },
      },
    },
    '/api/groups/{id}/checkin-safe': {
      post: {
        summary: 'Member Safe Arrival Check-in ("I am safe")',
        security: [{ BearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'Safe arrival recorded' } },
      },
    },
    '/api/chat/{groupId}': {
      get: {
        summary: 'Get Active Walk Chat Log',
        security: [{ BearerAuth: [] }],
        parameters: [{ name: 'groupId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'Chat messages' } },
      },
      post: {
        summary: 'Post Message or Quick Action',
        security: [{ BearerAuth: [] }],
        parameters: [{ name: 'groupId', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['message'],
                properties: {
                  message: { type: 'string', example: "I've arrived at your gate" },
                  quick_action: {
                    type: 'string',
                    enum: ['running_late', 'arrived', 'need_help', 'custom'],
                  },
                },
              },
            },
          },
        },
        responses: { '201': { description: 'Message sent' } },
      },
    },
    '/api/ehailing/start': {
      post: {
        summary: 'Start E-Hailing Mode (with BlackLyst check & SMS link)',
        security: [{ BearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['start_lat', 'start_lng'],
                properties: {
                  service_provider: { type: 'string', example: 'Uber' },
                  driver_name: { type: 'string', example: 'Bongani' },
                  vehicle_registration: { type: 'string', example: 'CA 123-456' },
                  start_lat: { type: 'number', example: -26.2041 },
                  start_lng: { type: 'number', example: 28.0473 },
                },
              },
            },
          },
        },
        responses: { '200': { description: 'Trip started, live tracking link generated' } },
      },
    },
    '/api/ehailing/track/{id}': {
      get: {
        summary: 'Public Live Tracking Link for Guardian Angels',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { '200': { description: 'Trip coordinates and driver details' } },
      },
    },
    '/api/sos/trigger': {
      post: {
        summary: 'Trigger SOS Emergency (Simultaneous Guardian Broadcast)',
        security: [{ BearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['latitude', 'longitude'],
                properties: {
                  latitude: { type: 'number', example: -26.2041 },
                  longitude: { type: 'number', example: 28.0473 },
                  trigger_type: {
                    type: 'string',
                    enum: ['app_sos', 'hardware_volume', 'checkpoint_timeout', 'ussd_report'],
                  },
                  distress_message: { type: 'string' },
                },
              },
            },
          },
        },
        responses: { '200': { description: 'SOS triggered' } },
      },
    },
    '/api/sos/{id}/acknowledge': {
      post: {
        summary: 'Guardian Angel Acknowledgment ("Received - I\'m on it")',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['guardian_name'],
                properties: { guardian_name: { type: 'string', example: 'Sis Nomvula' } },
              },
            },
          },
        },
        responses: { '200': { description: 'Acknowledgment registered' } },
      },
    },
    '/api/safety-map/flags': {
      get: {
        summary: 'Query Safety Flags within Radius',
        parameters: [
          { name: 'lat', in: 'query', schema: { type: 'number' } },
          { name: 'lng', in: 'query', schema: { type: 'number' } },
          { name: 'radius', in: 'query', schema: { type: 'number' } },
        ],
        responses: { '200': { description: 'List of active flags' } },
      },
      post: {
        summary: 'Drop Manual Safety Pin',
        security: [{ BearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['latitude', 'longitude', 'reason'],
                properties: {
                  latitude: { type: 'number', example: -26.2041 },
                  longitude: { type: 'number', example: 28.0473 },
                  reason: {
                    type: 'string',
                    enum: ['poor_lighting', 'harassment', 'isolated', 'suspicious_activity', 'other'],
                  },
                  severity: { type: 'string', enum: ['low', 'medium', 'high', 'severe'] },
                  description: { type: 'string', example: 'Dark street corner with no lights' },
                },
              },
            },
          },
        },
        responses: { '201': { description: 'Safety flag created' } },
      },
    },
    '/api/ussd': {
      post: {
        summary: 'Africa\'s Talking USSD Gateway Webhook (Phone-lost reporting)',
        requestBody: {
          required: true,
          content: {
            'application/x-www-form-urlencoded': {
              schema: {
                type: 'object',
                properties: {
                  sessionId: { type: 'string' },
                  phoneNumber: { type: 'string' },
                  text: { type: 'string', example: '0102030405089*1*1' },
                },
              },
            },
          },
        },
        responses: { '200': { description: 'USSD CON/END screen response' } },
      },
    },
  },
};
