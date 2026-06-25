const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');

// GET /api/tickets
const getTickets = async (req, res) => {
  const { status, priority, category, assigned_to, search } = req.query;
  const limit = parseInt(req.query.limit || '20');
  const offset = parseInt(req.query.offset || '0');
  const userId = req.user.id;
  const role = req.user.role;

  try {
    let queryText = `
      SELECT t.*, 
             u.name AS user_name, u.email AS user_email, u.role AS user_role,
             a.name AS assignee_name, a.email AS assignee_email, a.role AS assignee_role
      FROM tickets t
      LEFT JOIN profiles u ON t.user_id = u.id
      LEFT JOIN profiles a ON t.assigned_to = a.id
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    // 1. Role-based filtration (RLS emulation)
    if (role === 'user') {
      queryText += ` AND t.user_id = $${paramIndex++}`;
      params.push(userId);
    }

    // 2. Query Filters
    if (status && status !== 'all') {
      queryText += ` AND t.status = $${paramIndex++}`;
      params.push(status);
    }
    if (priority) {
      queryText += ` AND t.priority = $${paramIndex++}`;
      params.push(priority);
    }
    if (category) {
      queryText += ` AND t.category = $${paramIndex++}`;
      params.push(category);
    }
    if (assigned_to) {
      queryText += ` AND t.assigned_to = $${paramIndex++}`;
      params.push(assigned_to);
    }
    if (search && search.trim() !== '') {
      queryText += ` AND (t.title ILIKE $${paramIndex} OR t.description ILIKE $${paramIndex} OR t.ticket_no ILIKE $${paramIndex})`;
      params.push(`%${search.trim()}%`);
      paramIndex++;
    }

    // Calculate total count first
    const countQueryText = queryText.replace(
      'SELECT t.*, \n             u.name AS user_name, u.email AS user_email, u.role AS user_role,\n             a.name AS assignee_name, a.email AS assignee_email, a.role AS assignee_role',
      'SELECT COUNT(*)'
    );
    const countResult = await db.query(countQueryText, params);
    const total = parseInt(countResult.rows[0].count);

    // Apply sorting and pagination
    queryText += ` ORDER BY t.created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(limit, offset);

    const ticketsResult = await db.query(queryText, params);

    const tickets = ticketsResult.rows.map((r) => ({
      id: r.id,
      ticket_no: r.ticket_no,
      title: r.title,
      description: r.description,
      category: r.category,
      priority: r.priority,
      status: r.status,
      user_id: r.user_id,
      assigned_to: r.assigned_to,
      created_at: r.created_at,
      updated_at: r.updated_at,
      user: {
        id: r.user_id,
        name: r.user_name,
        email: r.user_email,
        role: r.user_role
      },
      assignee: r.assigned_to
        ? {
            id: r.assigned_to,
            name: r.assignee_name,
            email: r.assignee_email,
            role: r.assignee_role
          }
        : null
    }));

    return res.status(200).json({
      success: true,
      message: 'Tickets retrieved successfully',
      data: {
        tickets,
        total,
        limit,
        offset
      }
    });
  } catch (error) {
    console.error('Get Tickets Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

// GET /api/tickets/:id
const getTicketById = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const role = req.user.role;

  try {
    const ticketResult = await db.query(
      `SELECT t.*, 
              u.name AS user_name, u.email AS user_email, u.role AS user_role,
              a.name AS assignee_name, a.email AS assignee_email, a.role AS assignee_role
       FROM tickets t
       LEFT JOIN profiles u ON t.user_id = u.id
       LEFT JOIN profiles a ON t.assigned_to = a.id
       WHERE t.id = $1`,
      [id]
    );

    if (ticketResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Not Found',
        error: {
          message: 'Not Found',
          statusCode: 404,
          details: `Ticket dengan ID '${id}' tidak ditemukan`
        }
      });
    }

    const ticket = ticketResult.rows[0];

    // Access control: User can only see their own tickets
    if (role === 'user' && ticket.user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden',
        error: {
          message: 'Forbidden',
          statusCode: 403,
          details: 'Anda tidak punya akses ke ticket ini'
        }
      });
    }

    // Fetch comments
    // Filter internal comments: regular users cannot see internal comments
    const showInternal = role !== 'user';
    const commentsResult = await db.query(
      `SELECT tc.*, u.name AS user_name, u.role AS user_role
       FROM ticket_comments tc
       LEFT JOIN profiles u ON tc.user_id = u.id
       WHERE tc.ticket_id = $1 ${!showInternal ? 'AND tc.is_internal = false' : ''}
       ORDER BY tc.created_at ASC`,
      [id]
    );

    const comments = commentsResult.rows.map((c) => ({
      id: c.id,
      ticket_id: c.ticket_id,
      content: c.content,
      user_id: c.user_id,
      created_at: c.created_at,
      is_internal: c.is_internal,
      user: {
        id: c.user_id,
        name: c.user_name,
        role: c.user_role
      }
    }));

    // Fetch attachments
    const attachmentsResult = await db.query(
      'SELECT * FROM ticket_attachments WHERE ticket_id = $1 ORDER BY created_at ASC',
      [id]
    );

    // Fetch history
    const historyResult = await db.query(
      `SELECT th.*, u.name AS user_name
       FROM ticket_history th
       LEFT JOIN profiles u ON th.changed_by = u.id
       WHERE th.ticket_id = $1
       ORDER BY th.created_at DESC`,
      [id]
    );

    const history = historyResult.rows.map((h) => ({
      id: h.id,
      old_status: h.old_status,
      new_status: h.new_status,
      note: h.note,
      changed_by: h.changed_by,
      created_at: h.created_at,
      user: {
        id: h.changed_by,
        name: h.user_name
      }
    }));

    const responseData = {
      id: ticket.id,
      ticket_no: ticket.ticket_no,
      title: ticket.title,
      description: ticket.description,
      category: ticket.category,
      priority: ticket.priority,
      status: ticket.status,
      user_id: ticket.user_id,
      assigned_to: ticket.assigned_to,
      created_at: ticket.created_at,
      updated_at: ticket.updated_at,
      user: {
        id: ticket.user_id,
        name: ticket.user_name,
        email: ticket.user_email,
        role: ticket.user_role
      },
      assignee: ticket.assigned_to
        ? {
            id: ticket.assigned_to,
            name: ticket.assignee_name,
            email: ticket.assignee_email,
            role: ticket.assignee_role
          }
        : null,
      comments,
      attachments: attachmentsResult.rows,
      history
    };

    return res.status(200).json({
      success: true,
      message: 'Ticket retrieved successfully',
      data: responseData
    });
  } catch (error) {
    console.error('Get Ticket Detail Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

// POST /api/tickets
const createTicket = async (req, res) => {
  const { title, description, category, priority } = req.body;
  const userId = req.user.id;

  if (!title || !description || !category) {
    return res.status(400).json({
      success: false,
      message: 'Bad Request',
      error: {
        message: 'Bad Request',
        statusCode: 400,
        details: 'Title, description, and category are required'
      }
    });
  }

  try {
    const id = uuidv4();
    const status = 'open';
    const ticketPriority = priority || 'medium';

    // Generate ticket number sequentially
    const countResult = await db.query('SELECT COUNT(*) FROM tickets');
    const count = parseInt(countResult.rows[0].count) + 1;
    const ticketNo = `TKT-${String(count).padStart(3, '0')}`;

    const newTicketResult = await db.query(
      `INSERT INTO tickets (id, ticket_no, title, description, category, priority, status, user_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [id, ticketNo, title, description, category, ticketPriority, status, userId]
    );

    const ticket = newTicketResult.rows[0];

    // Log creation to ticket history
    const historyId = uuidv4();
    await db.query(
      `INSERT INTO ticket_history (id, ticket_id, old_status, new_status, note, changed_by)
       VALUES ($1, $2, NULL, $3, $4, $5)`,
      [historyId, id, status, 'Ticket created', userId]
    );

    // Auto-create notification for ticket creator
    await createNotification(
      userId,
      'Tiket Baru Dibuat',
      `Tiket Anda dengan nomor ${ticketNo} (${title}) berhasil dibuat.`
    );

    return res.status(201).json({
      success: true,
      message: 'Ticket created successfully',
      data: ticket
    });
  } catch (error) {
    console.error('Create Ticket Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

// PUT /api/tickets/:id
const updateTicket = async (req, res) => {
  const { id } = req.params;
  const { title, description, category, status, priority, assigned_to, note } = req.body;
  const userId = req.user.id;
  const role = req.user.role;

  try {
    // Check if ticket exists
    const ticketQuery = await db.query('SELECT * FROM tickets WHERE id = $1', [id]);
    if (ticketQuery.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Not Found',
        error: {
          message: 'Not Found',
          statusCode: 404,
          details: 'Ticket tidak ditemukan'
        }
      });
    }

    const currentTicket = ticketQuery.rows[0];

    // Access control: regular user can only update their own tickets
    if (role === 'user' && currentTicket.user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden',
        error: {
          message: 'Forbidden',
          statusCode: 403,
          details: 'Anda tidak punya akses untuk update ticket ini'
        }
      });
    }

    // Build update fields
    const updates = [];
    const values = [];
    let paramIndex = 1;

    // Regular users can only update details, not status, priority, or assignee (unless they close their own ticket)
    if (role === 'user') {
      if (title !== undefined) {
        updates.push(`title = $${paramIndex++}`);
        values.push(title);
      }
      if (description !== undefined) {
        updates.push(`description = $${paramIndex++}`);
        values.push(description);
      }
      if (category !== undefined) {
        updates.push(`category = $${paramIndex++}`);
        values.push(category);
      }
      // Allowed to close their own ticket
      if (status !== undefined && status === 'closed' && currentTicket.status !== 'closed') {
        updates.push(`status = $${paramIndex++}`);
        values.push(status);
      }
    } else {
      // Support & Admin can update all fields
      if (title !== undefined) {
        updates.push(`title = $${paramIndex++}`);
        values.push(title);
      }
      if (description !== undefined) {
        updates.push(`description = $${paramIndex++}`);
        values.push(description);
      }
      if (category !== undefined) {
        updates.push(`category = $${paramIndex++}`);
        values.push(category);
      }
      if (status !== undefined) {
        updates.push(`status = $${paramIndex++}`);
        values.push(status);
      }
      if (priority !== undefined) {
        updates.push(`priority = $${paramIndex++}`);
        values.push(priority);
      }
      if (assigned_to !== undefined) {
        updates.push(`assigned_to = $${paramIndex++}`);
        values.push(assigned_to || null);
      }
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Bad Request',
        error: {
          message: 'Bad Request',
          statusCode: 400,
          details: 'No fields to update'
        }
      });
    }

    // Set updated_at timestamp
    updates.push(`updated_at = CURRENT_TIMESTAMP`);

    values.push(id);
    const queryText = `
      UPDATE tickets 
      SET ${updates.join(', ')} 
      WHERE id = $${paramIndex} 
      RETURNING *`;

    const updateResult = await db.query(queryText, values);
    const updatedTicket = updateResult.rows[0];

    // Log to history if status has changed
    if (status !== undefined && currentTicket.status !== status) {
      const historyId = uuidv4();
      await db.query(
        `INSERT INTO ticket_history (id, ticket_id, old_status, new_status, note, changed_by)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          historyId,
          id,
          currentTicket.status,
          status,
          note || (role === 'user' ? 'Ticket closed by customer' : `Status updated to ${status}`),
          userId
        ]
      );

      // Notify customer that ticket status updated
      const statusMap = {
        'open': 'Open',
        'in_progress': 'In Progress',
        'resolved': 'Resolved',
        'closed': 'Closed'
      };
      const newStatusDisp = statusMap[status] || status;
      await createNotification(
        currentTicket.user_id,
        'Status Tiket Diperbarui',
        `Tiket #${currentTicket.ticket_no} Anda telah diubah statusnya menjadi: ${newStatusDisp}`
      );
    }

    // Notify assignee if assigned_to changed
    if (assigned_to !== undefined && assigned_to !== currentTicket.assigned_to && assigned_to !== null) {
      await createNotification(
        assigned_to,
        'Penugasan Tiket Baru',
        `Anda telah ditugaskan untuk menangani Tiket #${currentTicket.ticket_no}`
      );
    }

    return res.status(200).json({
      success: true,
      message: 'Ticket updated successfully',
      data: updatedTicket
    });
  } catch (error) {
    console.error('Update Ticket Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

// DELETE /api/tickets/:id
const deleteTicket = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const role = req.user.role;

  try {
    const ticketQuery = await db.query('SELECT * FROM tickets WHERE id = $1', [id]);
    if (ticketQuery.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Not Found',
        error: {
          message: 'Not Found',
          statusCode: 404,
          details: 'Ticket tidak ditemukan'
        }
      });
    }

    const ticket = ticketQuery.rows[0];

    // Only Admin can delete tickets, or User can delete their own open tickets
    if (role !== 'admin' && !(role === 'user' && ticket.user_id === userId && ticket.status === 'open')) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden',
        error: {
          message: 'Forbidden',
          statusCode: 403,
          details: 'Anda tidak punya akses untuk delete ticket ini'
        }
      });
    }

    await db.query('DELETE FROM tickets WHERE id = $1', [id]);

    return res.status(200).json({
      success: true,
      message: 'Ticket deleted successfully',
      data: {
        message: 'Ticket deleted successfully'
      }
    });
  } catch (error) {
    console.error('Delete Ticket Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

// POST /api/tickets/:id/comments
const addComment = async (req, res) => {
  const { id } = req.params;
  const { content, is_internal } = req.body;
  const userId = req.user.id;
  const role = req.user.role;

  if (!content || content.trim() === '') {
    return res.status(400).json({
      success: false,
      message: 'Bad Request',
      error: {
        message: 'Bad Request',
        statusCode: 400,
        details: 'Comment content is required'
      }
    });
  }

  try {
    // Check if ticket exists
    const ticketQuery = await db.query('SELECT * FROM tickets WHERE id = $1', [id]);
    if (ticketQuery.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Not Found',
        error: {
          message: 'Not Found',
          statusCode: 404,
          details: 'Ticket tidak ditemukan'
        }
      });
    }

    const ticket = ticketQuery.rows[0];

    // Regular users cannot add internal notes
    const isInternalComment = role === 'user' ? false : (is_internal || false);

    // Regular users can only comment on their own tickets
    if (role === 'user' && ticket.user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden',
        error: {
          message: 'Forbidden',
          statusCode: 403,
          details: 'Anda tidak punya akses ke ticket ini'
        }
      });
    }

    const commentId = uuidv4();
    const newCommentResult = await db.query(
      `INSERT INTO ticket_comments (id, ticket_id, user_id, content, is_internal)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [commentId, id, userId, content, isInternalComment]
    );

    const comment = newCommentResult.rows[0];

    return res.status(201).json({
      success: true,
      message: 'Comment added successfully',
      data: {
        id: comment.id,
        ticket_id: comment.ticket_id,
        content: comment.content,
        user_id: comment.user_id,
        created_at: comment.created_at,
        is_internal: comment.is_internal,
        user: {
          id: req.user.id,
          name: req.user.name,
          role: req.user.role
        }
      }
    });
  } catch (error) {
    console.error('Add Comment Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

// GET /api/tickets/:id/comments
const getComments = async (req, res) => {
  const { id } = req.params;
  const includeInternal = req.query.include_internal === 'true';
  const userId = req.user.id;
  const role = req.user.role;

  try {
    // Check if ticket exists
    const ticketQuery = await db.query('SELECT * FROM tickets WHERE id = $1', [id]);
    if (ticketQuery.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Not Found',
        error: {
          message: 'Not Found',
          statusCode: 404,
          details: 'Ticket tidak ditemukan'
        }
      });
    }

    const ticket = ticketQuery.rows[0];

    // Regular users can only see comments of their own tickets
    if (role === 'user' && ticket.user_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden',
        error: {
          message: 'Forbidden',
          statusCode: 403,
          details: 'Anda tidak punya akses ke ticket ini'
        }
      });
    }

    // Regular users never see internal comments
    const showInternal = role !== 'user' && includeInternal;

    const commentsResult = await db.query(
      `SELECT tc.*, u.name AS user_name, u.role AS user_role
       FROM ticket_comments tc
       LEFT JOIN profiles u ON tc.user_id = u.id
       WHERE tc.ticket_id = $1 ${!showInternal ? 'AND tc.is_internal = false' : ''}
       ORDER BY tc.created_at ASC`,
      [id]
    );

    const comments = commentsResult.rows.map((c) => ({
      id: c.id,
      ticket_id: c.ticket_id,
      content: c.content,
      user_id: c.user_id,
      created_at: c.created_at,
      is_internal: c.is_internal,
      user: {
        id: c.user_id,
        name: c.user_name,
        role: c.user_role
      }
    }));

    return res.status(200).json({
      success: true,
      message: 'Comments retrieved successfully',
      data: {
        comments,
        total: comments.length
      }
    });
  } catch (error) {
    console.error('Get Comments Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

// Helper for creating notifications
const createNotification = async (userId, title, message) => {
  if (!userId) return;
  try {
    const id = uuidv4();
    await db.query(
      'INSERT INTO notifications (id, user_id, title, message) VALUES ($1, $2, $3, $4)',
      [id, userId, title, message]
    );
    console.log(`🔔 Notification logged for ${userId}: [${title}] ${message}`);
  } catch (error) {
    console.error('❌ Failed to log notification:', error.message);
  }
};

// POST /api/tickets/:id/attachments (File upload)
const uploadAttachment = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: 'Bad Request',
      error: {
        message: 'Bad Request',
        statusCode: 400,
        details: 'No file uploaded'
      }
    });
  }

  try {
    // Check if ticket exists
    const ticketQuery = await db.query('SELECT * FROM tickets WHERE id = $1', [id]);
    if (ticketQuery.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Not Found',
        error: {
          message: 'Not Found',
          statusCode: 404,
          details: 'Ticket tidak ditemukan'
        }
      });
    }

    const attachmentId = uuidv4();
    const fileName = req.file.originalname;
    const fileType = req.file.mimetype;
    const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    await db.query(
      `INSERT INTO ticket_attachments (id, ticket_id, file_url, file_name, file_type)
       VALUES ($1, $2, $3, $4, $5)`,
      [attachmentId, id, fileUrl, fileName, fileType]
    );

    return res.status(201).json({
      success: true,
      message: 'Attachment uploaded successfully',
      data: {
        url: fileUrl,
        path: req.file.path
      }
    });
  } catch (error) {
    console.error('Upload Attachment Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

module.exports = {
  getTickets,
  getTicketById,
  createTicket,
  updateTicket,
  deleteTicket,
  addComment,
  getComments,
  uploadAttachment,
};
