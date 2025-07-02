import Bill from "../models/bill.model.js"
import TableSession from "../models/table-session.model.js"
import {Table} from "../models/table.model.js"
import {Order} from "../models/order.model.js"

// Get bill by ID
export const getBillById = async (req, res, next) => {
  try {
    const { billId } = req.params

    const bill = await Bill.findById(billId)
      .populate("tableSessionId", "tableId startTime endTime")
      .populate("processedBy", "fullName")

    if (!bill) {
      return res.status(404).json({ message: "Bill not found" })
    }

    res.status(200).json({ bill })
  } catch (error) {
    next(error)
  }
}

// Get bill by table session
export const getBillByTableSession = async (req, res, next) => {
  try {
    const { sessionId } = req.params

    const bill = await Bill.findOne({ tableSessionId: sessionId })
      .populate("tableSessionId", "tableId startTime endTime")
      .populate("processedBy", "fullName")

    if (!bill) {
      return res.status(404).json({ message: "Bill not found for this session" })
    }

    res.status(200).json({ bill })
  } catch (error) {
    next(error)
  }
}

// Get all bills (admin only)
export const getAllBills = async (req, res, next) => {
  try {
    const { status, startDate, endDate } = req.query

    const query = {}

    if (status) {
      query.paymentStatus = status
    }

    if (startDate && endDate) {
      query.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      }
    }

    const bills = await Bill.find(query)
      .populate("tableSessionId", "tableId startTime endTime")
      .populate("processedBy", "fullName")
      .sort({ createdAt: -1 })

    res.status(200).json({ bills })
  } catch (error) {
    next(error)
  }
}

// Update bill payment status
export const updateBillPaymentStatus = async (req, res, next) => {
  try {
    const { billId } = req.params
    const { paymentStatus, paymentMethod } = req.body

    if (!paymentStatus) {
      return res.status(400).json({ message: "Payment status is required" })
    }

    const bill = await Bill.findById(billId)

    if (!bill) {
      return res.status(404).json({ message: "Bill not found" })
    }

    // Update bill
    bill.paymentStatus = paymentStatus
    if (paymentMethod) {
      bill.paymentMethod = paymentMethod
    }
    bill.processedBy = req.userId // Set by auth middleware

    await bill.save()

    // If bill is paid, update session and table status
    if (paymentStatus === "paid") {
      const session = await TableSession.findById(bill.tableSessionId)
      if (session && session.status !== "closed") {
        session.status = "closed"
        session.endTime = new Date()
        await session.save()

        // Update table status
        const table = await Table.findById(session.tableId)
        if (table) {
          table.status = "cleaning"
          table.currentSession = null
          await table.save()
        }
      }
    }

    res.status(200).json({
      message: "Bill payment status updated successfully",
      bill: {
        id: bill._id,
        paymentStatus: bill.paymentStatus,
        paymentMethod: bill.paymentMethod,
      },
    })
  } catch (error) {
    next(error)
  }
}

// Generate bill for session
export const generateBillForSession = async (req, res, next) => {
  try {
    const { sessionId } = req.params

    // Check if bill already exists
    const existingBill = await Bill.findOne({ tableSessionId: sessionId })
    if (existingBill) {
      return res.status(400).json({
        message: "Bill already exists for this session",
        billId: existingBill._id,
      })
    }

    const session = await TableSession.findById(sessionId)
    if (!session) {
      return res.status(404).json({ message: "Session not found" })
    }

    // Get all orders for this session
    const orders = await Order.find({ _id: { $in: session.orders } })

    // Calculate total
    const total = orders.reduce((sum, order) => sum + order.total, 0)

    // Create bill
    const bill = new Bill({
      tableSessionId: sessionId,
      total,
      paymentStatus: "pending",
    })

    await bill.save()

    // Update session status
    session.status = "payment_pending"
    await session.save()

    res.status(201).json({
      message: "Bill generated successfully",
      bill: {
        id: bill._id,
        total: bill.total,
        paymentStatus: bill.paymentStatus,
      },
    })
  } catch (error) {
    next(error)
  }
}

// End session and generate bill
export const endSessionAndGenerateBill = async (req, res, next) => {
  try {
    const { sessionId } = req.params

    const session = await TableSession.findById(sessionId)
    if (!session) {
      return res.status(404).json({ message: "Session not found" })
    }

    if (session.status === "closed") {
      return res.status(400).json({ message: "Session is already closed" })
    }

    // Check if bill already exists
    let bill = await Bill.findOne({ tableSessionId: sessionId })

    if (!bill) {
      // Get all orders for this session
      const orders = await Order.find({ _id: { $in: session.orders } })

      // Calculate total
      const total = orders.reduce((sum, order) => sum + order.total, 0)

      // Create bill
      bill = new Bill({
        tableSessionId: sessionId,
        total,
        paymentStatus: "pending",
      })

      await bill.save()
    }

    // Update session status
    session.status = "payment_pending"
    await session.save()

    res.status(200).json({
      message: "Session ended and bill generated successfully",
      bill: {
        id: bill._id,
        total: bill.total,
        paymentStatus: bill.paymentStatus,
      },
    })
  } catch (error) {
    next(error)
  }
}

///////////////////////////////////////////////////////
// Les autres modèles seront importés implicitement via les populate dans les requêtes Mongoose
// mais il est bon de les avoir à l'esprit: Order, MenuItem, Table, User

// --- Contrôleur pour récupérer les factures impayées de l'utilisateur ---
export const getMyUnpaidBills = async (req, res) => {
  try {
    const userId = req.user._id; // Provenant de authMiddleware

    // 1. Trouver les sessions de table fermées pour cet utilisateur
    const userClosedSessions = await TableSession.find({
      clientId: userId,
      status: 'closed', // Ou votre statut pour une session terminée attendant paiement
    }).select('_id'); // On a besoin que des IDs pour la prochaine étape

    if (!userClosedSessions || userClosedSessions.length === 0) {
      return res.json([]); // Pas de sessions pertinentes, donc pas de factures à afficher
    }

    const userClosedSessionIds = userClosedSessions.map(session => session._id);

    // 2. Trouver les factures impayées liées à ces sessions et populer les détails
    const unpaidBills = await Bill.find({
      tableSessionId: { $in: userClosedSessionIds },
      paymentStatus: 'pending',
    })
    .populate({
      path: 'tableSessionId',
      model: 'TableSession',
      select: 'startTime tableId orders status clientId', // clientId pour la vérification
      populate: [
        {
          path: 'tableId',
          model: 'Table',
          select: 'name number', // Ce que vous voulez afficher pour la table
        },
        {
          path: 'orders',
          model: 'Order',
          select: 'items total status', // Champs à récupérer de chaque commande
          populate: {
            path: 'items.menuItem', // Le chemin vers l'ID du MenuItem
            model: 'MenuItem',      // Le nom de votre modèle MenuItem
            select: 'name price image', // Détails du plat
          },
        },
      ],
    })
    .sort({ createdAt: -1 }); // Les plus récentes en premier

    // 3. Formater pour correspondre au modèle attendu par Flutter (surtout pour les 'items' de la session)
    const formattedBills = unpaidBills.map(bill => {
      const billObject = bill.toObject(); // Convertir en objet simple

      // Sécurité : Double vérification que la session de la facture appartient bien à l'utilisateur
      // Cela est normalement déjà filtré par la première requête, mais une défense en profondeur est bien.
      if (billObject.tableSessionId?.clientId?.toString() !== userId) {
        // Ce cas ne devrait pas se produire si la logique est correcte, mais c'est une sécurité.
        // On pourrait choisir de filtrer cet élément ou de lever une erreur.
        // Pour l'instant, on le laisse passer car le filtrage initial devrait être suffisant.
      }

      if (billObject.tableSessionId && billObject.tableSessionId.orders) {
        const sessionItemsDetails = [];
        billObject.tableSessionId.orders.forEach(order => {
          if (order.items && order.items.length > 0) {
            order.items.forEach(item => {
              sessionItemsDetails.push({
                menuItemId: item.menuItem?._id?.toString() || item.menuItemId?.toString(),
                name: item.menuItem?.name || item.name || 'Article inconnu', // item.name si menuItem n'est pas populé mais que vous stockez le nom
                price: item.menuItem?.price || item.price, // Idem pour le prix
                image: item.menuItem?.image || item.image, // Idem pour l'image
                quantity: item.quantity,
              });
            });
          }
        });
        // Remplacer la structure 'orders' par la liste aplatie 'items' pour la session
        billObject.tableSessionId.items = sessionItemsDetails;
        // delete billObject.tableSessionId.orders; // Optionnel: nettoyer si le client n'a pas besoin de 'orders'
      }
      return billObject;
    });

    res.json(formattedBills);

  } catch (error) {
    console.error("Erreur dans getMyUnpaidBills controller:", error);
    res.status(500).json({ message: "Erreur serveur lors de la récupération des factures impayées." });
  }
};

// --- Contrôleur pour marquer une facture comme payée ---
export const markBillAsPaid = async (req, res) => {
  try {
    const { billId } = req.params;
    const userId = req.user._id; // Provenant de authMiddleware
    const { paymentMethodDetails, transactionDetails } = req.body; // Infos optionnelles du paiement

    // 1. Trouver la facture et vérifier l'appartenance (via la session de table liée)
    const billToUpdate = await Bill.findById(billId)
      .populate({
        path: 'tableSessionId',
        select: 'clientId status', // On a besoin de clientId pour la vérification et status pour une logique éventuelle
      });

    if (!billToUpdate) {
      return res.status(404).json({ message: "Facture non trouvée." });
    }
    console.log(billToUpdate.tableSessionId.clientId.toString(), userId.toString())
    // Sécurité: S'assurer que la facture (via sa session) appartient à l'utilisateur qui fait la requête
    if (billToUpdate.tableSessionId.clientId.toString() !== userId.toString()) {
      return res.status(403).json({ message: "Accès non autorisé à cette facture." });
    }

    // Vérifier si elle est déjà payée pour éviter des écritures inutiles
    if (billToUpdate.paymentStatus === 'paid') {
      return res.status(200).json({ message: "Cette facture est déjà marquée comme payée.", bill: billToUpdate });
    }

    // 2. Mettre à jour la facture
    billToUpdate.paymentStatus = 'paid';
    billToUpdate.paymentMethod = 'mobile_payment'; // 'stripe_mobile_client' ou ce que le client envoie
    // Vous pourriez vouloir stocker des informations de transaction si disponibles
    // if (transactionDetails) billToUpdate.transactionDetails = transactionDetails;
    // billToUpdate.processedBy = null; // Si le paiement est fait par le client lui-même

    const updatedBill = await billToUpdate.save();

    // Optionnel: Mettre à jour le statut de la TableSession si nécessaire
    // Par exemple, si une session 'closed' devient 'completed_paid'
    // await TableSession.findByIdAndUpdate(billToUpdate.tableSessionId._id, { status: 'completed_paid' });

    res.status(200).json({ message: "Facture marquée comme payée avec succès.", bill: updatedBill });

  } catch (error) {
    console.error("Erreur dans markBillAsPaid controller:", error);
    res.status(500).json({ message: "Erreur serveur lors de la mise à jour de la facture." });
  }
};
